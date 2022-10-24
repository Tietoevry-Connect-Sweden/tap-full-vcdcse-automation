#!/bin/bash
# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: BSD-2-Clause
source var.conf

#export TAP_NAMESPACE="tap-install"
export TAP_REGISTRY_USER=$registry_user
export TAP_REGISTRY_SERVER_ORIGINAL=$registry_url
if [ $registry_url = "${DOCKERHUB_REGISTRY_URL}" ]
then
  export TAP_REGISTRY_SERVER=$TAP_REGISTRY_USER
  export TAP_REGISTRY_REPOSITORY=$TAP_REGISTRY_USER
else
  export TAP_REGISTRY_SERVER=$registry_url
  export TAP_REGISTRY_REPOSITORY="supply-chain"
fi
export TAP_REGISTRY_PASSWORD=$registry_password
#export TAP_VERSION=1.1.0
export INSTALL_REGISTRY_USERNAME=$tanzu_net_reg_user
export INSTALL_REGISTRY_PASSWORD=$tanzu_net_reg_password

cat <<EOF | tee tap-gui-viewer-service-account-rbac.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tap-gui
---
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: tap-gui
  name: tap-gui-viewer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tap-gui-read-k8s
subjects:
- kind: ServiceAccount
  namespace: tap-gui
  name: tap-gui-viewer
roleRef:
  kind: ClusterRole
  name: k8s-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: k8s-reader
rules:
- apiGroups: ['']
  resources: ['pods', 'services', 'configmaps']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['apps']
  resources: ['deployments', 'replicasets']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['autoscaling']
  resources: ['horizontalpodautoscalers']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['networking.k8s.io']
  resources: ['ingresses']
  verbs: ['get', 'watch', 'list']
- apiGroups: ['networking.internal.knative.dev']
  resources: ['serverlessservices']
  verbs: ['get', 'watch', 'list']
- apiGroups: [ 'autoscaling.internal.knative.dev' ]
  resources: [ 'podautoscalers' ]
  verbs: [ 'get', 'watch', 'list' ]
- apiGroups: ['serving.knative.dev']
  resources:
  - configurations
  - revisions
  - routes
  - services
  verbs: ['get', 'watch', 'list']
- apiGroups: ['carto.run']
  resources:
  - clusterconfigtemplates
  - clusterdeliveries
  - clusterdeploymenttemplates
  - clusterimagetemplates
  - clusterruntemplates
  - clustersourcetemplates
  - clustersupplychains
  - clustertemplates
  - deliverables
  - runnables
  - workloads
  verbs: ['get', 'watch', 'list']
- apiGroups: ['source.toolkit.fluxcd.io']
  resources:
  - gitrepositories
  verbs: ['get', 'watch', 'list']
- apiGroups: ['source.apps.tanzu.vmware.com']
  resources:
  - imagerepositories
  verbs: ['get', 'watch', 'list']
- apiGroups: ['conventions.apps.tanzu.vmware.com']
  resources:
  - podintents
  verbs: ['get', 'watch', 'list']
- apiGroups: ['kpack.io']
  resources:
  - images
  - builds
  verbs: ['get', 'watch', 'list']
- apiGroups: ['scanning.apps.tanzu.vmware.com']
  resources:
  - sourcescans
  - imagescans
  - scanpolicies
  verbs: ['get', 'watch', 'list']
- apiGroups: ['tekton.dev']
  resources:
  - taskruns
  - pipelineruns
  verbs: ['get', 'watch', 'list']
- apiGroups: ['kappctrl.k14s.io']
  resources:
  - apps
  verbs: ['get', 'watch', 'list']

EOF

kubectl create -f tap-gui-viewer-service-account-rbac.yaml

CLUSTER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

CLUSTER_TOKEN=$(kubectl -n tap-gui get secret $(kubectl -n tap-gui get sa tap-gui-viewer -o=json \
| jq -r '.secrets[0].name') -o=json \
| jq -r '.data["token"]' \
| base64 --decode)

echo CLUSTER_URL: $CLUSTER_URL
echo CLUSTER_TOKEN: $CLUSTER_TOKEN


# set the following variables
export TAP_REGISTRY_SERVER=$registry_url
export TAP_REGISTRY_USER=$registry_user
export TAP_REGISTRY_PASSWORD=$registry_password

cat <<EOF | tee tap-values-full.yaml
profile: full
ceip_policy_disclosed: true

shared:
  ingress_domain: "${tap_cnrs_domain}"
  
contour:
  envoy:
    service:
      type: LoadBalancer

accelerator:
  server.service_type: ClusterIP
  ingress:
    include: "true"
  domain: "${tap_cnrs_domain}"

learningcenter:
  ingressDomain: "learning.${tap_cnrs_domain}"
  ingressClass: contour

tap_gui:
  service_type: ClusterIP
  ingressEnabled: "true"
  ingressDomain: "${tap_cnrs_domain}"
  tls:
    namespace: cert-manager
    secretName: tap-gui
  app_config:
    app:
      baseUrl: "https://tap-gui.${tap_cnrs_domain}"
    catalog:
      locations:
        - type: url
          target: ${tap_git_catalog_url}
    backend:
        baseUrl: "https://tap-gui.${tap_cnrs_domain}"
        cors:
          origin: "https://tap-gui.${tap_cnrs_domain}"
    proxy:
      /metadata-store:
        target: https://metadata-store-app.metadata-store:8443/api/v1
        changeOrigin: true
        secure: false
        headers:
          Authorization: "Bearer ${CLUSTER_TOKEN}"
          X-Custom-Source: project-star    
    kubernetes:
      serviceLocatorMethod:
        type: "multiTenant"
      clusterLocatorMethods:
        - type: "config"
          clusters:
            - url: ${CLUSTER_URL}
              name: ${TAP_RUN_CLUSTER_NAME}
              authProvider: "serviceAccount"
              skipTLSVerify: true
              skipMetricsLookup: true
              serviceAccountToken: "${CLUSTER_TOKEN}"

metadata_store:
  app_service_type: LoadBalancer

appliveview:
  ingressEnabled: true
  ingressDomain: "${tap_cnrs_domain}" 

buildservice:
  kp_default_repository: "${TAP_REGISTRY_SERVER}/build-service"
  kp_default_repository_username: "${TAP_REGISTRY_USER}"
  kp_default_repository_password: "${TAP_REGISTRY_PASSWORD}"
  tanzunet_username: "${INSTALL_REGISTRY_USERNAME}"
  tanzunet_password: "${INSTALL_REGISTRY_PASSWORD}"
  descriptor_name: "full"
  enable_automatic_dependency_updates: true

supply_chain: basic

ootb_supply_chain_basic:    
  registry:
    server: "${TAP_REGISTRY_SERVER_ORIGINAL}"
    repository: "${TAP_REGISTRY_REPOSITORY}"
  gitops:
    ssh_secret: ""
  cluster_builder: default
  service_account: default

grype:
  namespace: "default" 
  targetImagePullSecret: "tap-registry"
  metadataStore:
    url: "http://metadata-store.${tap_cnrs_domain}"
    caSecret:
        name: store-ca-cert
        importFromNamespace: metadata-store-secrets
    authSecret:
        name: store-auth-token
        importFromNamespace: metadata-store-secrets

scanning:
  metadataStore:
    url: "" # Disable embedded integration since it's deprecated

image_policy_webhook:
  allow_unmatched_images: true

cnrs:
  domain_name: "${tap_cnrs_domain}"

appliveview_connector:
  backend:
    sslDisabled: "true"
    host: appliveview.$alv_domain

EOF

tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file tap-values-full.yaml -n "${TAP_NAMESPACE}"
tanzu package installed get tap -n "${TAP_NAMESPACE}"

# Create Issuer and Certificate for tap-gui
cat <<EOF | tee tap-full-cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-http01-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ipablo@vmware.com
    privateKeySecretRef:
      name: letsencrypt-http01-issuer
    solvers:
      - http01:
          ingress:
            class: contour
EOF

cat <<EOF | tee tap-full-certificate.yaml

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  namespace: cert-manager
  name: tap-gui
spec:
  commonName: tap-gui.${tap_cnrs_domain}
  dnsNames:
  - tap-gui.${tap_cnrs_domain}
  issuerRef:
    name: letsencrypt-http01-issuer
    kind: ClusterIssuer
  secretName: tap-gui

EOF

kubectl create -f tap-full-cluster-issuer.yaml
kubectl create -f tap-full-certificate.yaml

# ensure all build cluster packages are installed succesfully
tanzu package installed list -A

kubectl get svc -n tanzu-system-ingress

# pick an external ip from service output and configure DNS wildcard records
# example - *.ui.customer0.io ==> <ingress external ip/cname>
