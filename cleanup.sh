#!/bin/bash

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ./.env)
IFS=$OLDIFS

# check if the cluster namespace exists
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${nsStatus}" ]; then
    echo "Cluster (${CLUSTER_NAME}) is not found, please use an existing cluster"
    exit 1;
fi

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

# delete validator clients
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./templates/validator-client.yaml)
EOF
" | kubectl delete -f -
((node_index=node_index+1))
done

# delete charon nodes
node_index=0
while [[ $node_index -lt "$CLUSTER_SIZE" ]]
do
export NODE_NAME="node$node_index"
export VC_INDEX="vc$node_index"
eval "cat <<EOF
$(<./templates/charon-node.yaml)
EOF
" | kubectl delete -f -
((node_index=node_index+1))
done

# delete charon bootnode
eval "cat <<EOF
$(<./templates/charon-bootnode.yaml)
EOF
" | kubectl delete -f -
