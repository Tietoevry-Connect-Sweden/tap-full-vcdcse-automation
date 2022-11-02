## Purpose

This project is designed to build a Tanzu Application Platform 1.2 single-cluster instance on VCD+CSE 4.x TKG Cluster that corresponds to the [Full TAP profile in the Official VMware Docs](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.2/tap/GUID-install-intro.html). 

This is a 1-step automation with minimum inputs into config files. This scripts assume that Tanzu Cluster essentials are already present in the TKG cluster.

* **Step 1** To install TAP full profile into a Tanzu K8S cluster.

Specifically, this automation will build:
- Install Tanzu Application Platform full profile on the VCD+CSE 4.x TKG cluster. 
- Install Tanzu Application Platform sample demo app. 

## [Prerequisites](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.2/tap/GUID-prerequisites.html)

* Install kubectl cli.
* An account with write permissions in a Docker Registry (DockerHub, Harbor, AWS ECR, Azure ACR).
* Have a Tanzu Network account and [Accept the Tanzu EULA](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.2/tap/GUID-install-tanzu-cli.html#accept-eulas).
* Network access to the Tanzu Public Registry: https://registry.tanzu.vmware.com
* A Git repository for tap-gui software catalogs (GitHub, Gitlab, Azure DevOps).

## Prepare the Environment

### Add TAP configuration mandatory details 

Add the following details into `/tap-scripts/var.conf` file to fullfill TAP prerequisites. Examples and default values are given in sample below. All fields are mandatory. They can't be leave blank and must be filled before executing the `tap-index.sh` script. Refer to the sample config file below. 

```
TAP_DEV_NAMESPACE="default"
os=<terminal os as m or l.  m for Mac , l for linux/ubuntu>
INSTALL_REGISTRY_HOSTNAME="registry.tanzu.vmware.com"
INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:e00f33b92d418f49b1af79f42cb13d6765f1c8c731f4528dfff8343af042dc3e
DOCKERHUB_REGISTRY_URL=index.docker.io
TAP_VERSION=1.2.0
TAP_NAMESPACE="tap-install"
tanzu_net_reg_user=<Provide tanzu net user>
tanzu_net_reg_password=<Provide tanzu net password>
tanzu_net_api_token=<Provide tanzu net token>
registry_url=<Provide user registry url>
registry_user=<Provide user registry userid>
registry_password=<Provide user registry password>

#TAP FULL
tap_cnrs_domain=<TAP cluster sub domain example like : full.ab-tap.customer0.io >
tap_git_catalog_url=<git catalog url example like : https://github.com/sendjainabhi/tap/blob/main/catalog-info.yaml>
TAP_CLUSTER_NAME=tap-full
TAP_CLUSTER_SERVER=<TAP cluster server URL address example like : https://A.B.C.D:6443 >
TAP_CLUSTER_USER=tap-full-admin
TAP_CLUSTER_CERT_FILE=<K8S user certificate file location>
TAP_CLUSTER_KEY_FILE=<K8S user certificate key location>
TAP_CLUSTER_CACERT_FILE=<K8S cluster CA certificate file location>

#tap-gui
TAP_GUI_CERT=<HTTPS FullChain cert absolute path  for tap-gui>
TAP_GUI_KEY=<HTTPS Key absolute path for tap-gui>

#tap demo app properties
TAP_APP_NAME="tap-demo"
TAP_APP_GIT_URL="https://github.com/sample-accelerators/spring-petclinic"
```

In the following lines you will find notes on how to obtain the values to fill some of the  required variables:

* tanzu_net_reg_user: Tanzu Network username. It is usually an email.
* tanzu_net_reg_password: Tanzu Network password. Special characters shall be scaped with the '\' character.
* tanzu_net_api_token: This token can be obtained in Tanzu Network by navigating to the User menu, Edit Profile, UAA API TOKEN and then clicking the button "REQUEST NEW REFRESH TOKEN".
* registry_url: If using Docker Hub, the registry URL shall be `index.docker.io`. This registry will be used to store all the builder images and the generated workload images.
* registry_user: Username of the container registry.
* registry_password: Password of the container registry. This password may be an access token issued by the registry.
* tap_git_catalog_url: GIT Url where the catalog yaml file for tap-gui is located.

## Install TAP

### Install TAP full profile in single cluster

Execute the following steps to install TAP in a single cluster 

```
#Step 1 - Add execute permission to tap-index.sh file
chmod +x /tap-scripts/tap-index.sh

#Step 2 - Run tap-index file 
./tap-scripts/tap-index.sh
```

### Create DNS records

Pick the external ip from service output from the K8S cluster and configure a DNS wildcard record in your dns server:

To obtain the External IP address, run the following command and pick the EXTERNAL-IP:
```
kubectl get svc envoy -n tanzu-system-ingress
```

* **Example full cluster** - *.full.customer0.io ==> <ingress external ip/cname>


### TAP scripts for specific tasks

If you got stuck in any specific stage and need to resume installation , you can use following scripts.

* **Install tanzu cli** - Run `./tap-scripts/tanzu-cli-setup.sh`

* **Install tanzu essentials** - Run `./tap-scripts/tanzu-essential-setup.sh` . This step is commented in the tap-full.sh script, as this automation project is for TKGm K8S clusters delivered by VCD+CSE. Tanzu Essentials shall be already installed.

* **Setup TAP repository** - Run `./tap-scripts/tanzu-repo.sh`  

* **Install TAP full profile packages** - Run `./tap-scripts/tanzu-full-profile.sh` 

When creating TKGm clusters with VCD+CSE, you can obtain the kubeconfig files as ' `kubeconfig-<clusterName>.txt` files. To extract the user key and certificate and the CA certificate, you can make use of the `helpers/extract-kubeconfig-certs.sh` script.

* **Extract Keys and Certificate files from Kubeconfig** - Copy `kubeconfig-<clusterName>.txt` files in the helpers folder and run `./tap-scripts/helpers/extract-kubeconfig-certs.sh <Cluster Name Prefix>`. e.g. if the kubeconfigfiles are a named kubeconfig-tap-full.txt, the <Cluster Name Prefix> parameter should be `-tap-`.

## Clean up

### Delete TAP instances from the K8S cluster

Follow below steps 
```

1. Log in to the K8S cluster where the full-profile TAP is installed, using `kubectl config use-context` command.
2. Run chmod +x /tap-scripts/tap-delete/tap-delete-single-cluster.sh
3. Run ./tap-scripts/tap-delete/tap-delete-single-cluster.sh

```