#!/bin/bash

for KUBECONFIG in $1
do
	echo "extracting certificates and keys from $i kubeconfig file"
	cat ${KUBECONFIG} | yq -r '.clusters[0].cluster."certificate-authority-data"' | base64 -d > tap-${KUBECONFIG}-cacert.pem
	cat ${KUBECONFIG} | yq -r '.users[0].user."client-certificate-data"' | base64 -d > tap-${KUBECONFIG}-cert.pem
	cat ${KUBECONFIG} | yq -r '.users[0].user."client-key-data"' | base64 -d > tap-${KUBECONFIG}-cert.key
done
