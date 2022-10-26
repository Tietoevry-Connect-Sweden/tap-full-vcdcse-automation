#!/bin/bash
# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: BSD-2-Clause
source var.conf

chmod +x tanzu-essential-setup.sh
chmod +x tap-repo.sh
chmod +x tap-view-profile.sh
chmod +x tap-dev-namespace.sh

chmod +x var-input-validatation.sh

./var-input-validatation.sh

echo  "Log in to View Cluster !!! "
kubectl config set-cluster ${TAP_CLUSTER_NAME} --server=${TAP_CLUSTER_SERVER} --certificate-authority=${TAP_CLUSTER_CACERT_FILE}
kubectl config set-credentials ${TAP_CLUSTER_USER} --client-certificate=${TAP_CLUSTER_CERT_FILE} --client-key=${TAP_CLUSTER_KEY_FILE}
kubectl config set-context ${TAP_CLUSTER_USER}@${TAP_CLUSTER_NAME} --cluster=${TAP_CLUSTER_NAME} --user=${TAP_CLUSTER_USER}
kubectl config use-context ${TAP_CLUSTER_USER}@${TAP_CLUSTER_NAME}

#echo "Step 1 => installing tanzu cli and tanzu essential in VIEW cluster !!!"
#./tanzu-essential-setup.sh
echo "Step 2 => installing TAP Repo in FULL cluster !!! "
./tap-repo.sh
echo "Step 3 => installing TAP FULL  Profile !!! "
./tap-full-profile.sh
echo "Step 4 => installing TAP developer namespace in FULL cluster !!! "
./tap-dev-namespace.sh
