#!/bin/bash

usage() { echo "Usage: $0 <namespace>" 1>&2; exit 1; }

if [[ -z $1 ]]; then
  usage
  exit 1;
fi

ns=$1

# verify that the namespace exists
nsStatus=`kubectl get namespace $1 --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Namespace (${ns}) not found, creating new namespace (${ns})"
    kubectl create namespace ${ns} --dry-run=client -o yaml | kubectl apply -f -
fi

# set the current namespace
echo "set namespace to $ns"
kubectl config set-context --current --namespace=$ns

# create vc keystore secrets
kubectl create secret generic keystore --from-file=keystore=./split_keys/keystore.json --from-file=password=./split_keys/keystore.txt

# deploy charon bootnode and configmaps
echo ">>> deploying charon bootnodes and configmaps."
kubectl apply -f bootnode

# deploy charon nodes
echo ">>> deploying charon charon nodes."
kubectl apply -f nodes

# deploy monitoring stack
echo ">>> deploying monitoring stack."
kubectl apply -f monitoring
