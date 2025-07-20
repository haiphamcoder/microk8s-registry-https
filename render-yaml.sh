#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if not provided
export REGISTRY_DOMAIN=${REGISTRY_DOMAIN}
export NAMESPACE=${NAMESPACE}
export SECRET_NAME=${SECRET_NAME}

echo "Rendering YAML files with environment variables:"
echo "REGISTRY_DOMAIN: $REGISTRY_DOMAIN"
echo "NAMESPACE: $NAMESPACE"
echo "SECRET_NAME: $SECRET_NAME"
echo ""

# Create rendered directory
mkdir -p rendered

# Render registry-ingress.yaml
envsubst < registry-ingress.yaml > rendered/registry-ingress.yaml
echo "✓ Rendered registry-ingress.yaml"

# Render registry deployment and service
envsubst < registry/registry-deployment.yaml > rendered/registry-deployment.yaml
envsubst < registry/registry-service.yaml > rendered/registry-service.yaml
echo "✓ Rendered registry files"

# Render registry-ui deployment and service
envsubst < registry-ui/registry-ui-deployment.yaml > rendered/registry-ui-deployment.yaml
envsubst < registry-ui/registry-ui-service.yaml > rendered/registry-ui-service.yaml
echo "✓ Rendered registry-ui files"

echo ""
echo "All files rendered in 'rendered/' directory"
echo "You can now apply them with: kubectl apply -f rendered/" 