#!/bin/bash
# Copyright 2022 VMware, Inc.
# SPDX-License-Identifier: BSD-2-Clause
source var.conf

# Remove incompatible kapp-controller found in CSE 3.1.3
kubectl delete  deployment/kapp-controller  -n kapp-controller
# Fix metada-store-db DB creation
kubectl apply -f csi-vcd-controllerplugin-statefulset.yam

chmod +x tap-full.sh
chmod +x tanzu-cli-setup.sh
chmod +x tap-demo-app-deploy.sh


chmod +x var-input-validatation.sh

./var-input-validatation.sh
echo "Step 1 => installing tanzu cli !!!"
./tanzu-cli-setup.sh
echo "Step 2 => Setup TAP Full Profile"
./tap-full.sh

echo "pick the external ip from the envoy service output in the tanzu-system-ingress namespace and configure a DNS wildcard record in your dns server"
echo "example full cluster - *.full.customer0.io ==> <ingress external ip/cname> " 

#echo "Step 3 => Deploy sample app"
#./tap-demo-app-deploy.sh
