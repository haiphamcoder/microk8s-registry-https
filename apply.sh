#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if not provided
export REGISTRY_DOMAIN=${REGISTRY_DOMAIN}
export NAMESPACE=${NAMESPACE}
export SECRET_NAME=${SECRET_NAME}

echo "Applying Kubernetes manifests with:"
echo "REGISTRY_DOMAIN: $REGISTRY_DOMAIN"
echo "NAMESPACE: $NAMESPACE"
echo "SECRET_NAME: $SECRET_NAME"
echo ""

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests using envsubst
echo "Applying registry deployment and service..."
envsubst < registry/registry-deployment.yaml | kubectl apply -f -
envsubst < registry/registry-service.yaml | kubectl apply -f -

echo "Applying registry-ui deployment and service..."
envsubst < registry-ui/registry-ui-deployment.yaml | kubectl apply -f -
envsubst < registry-ui/registry-ui-service.yaml | kubectl apply -f -

echo "Applying ingress..."
envsubst < registry-ingress.yaml | kubectl apply -f -

echo ""
echo "All manifests applied successfully!"
echo "Check status with: kubectl get all -n $NAMESPACE" 