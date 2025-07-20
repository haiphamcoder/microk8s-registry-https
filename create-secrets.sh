#!/bin/bash

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if not provided
export REGISTRY_DOMAIN=${REGISTRY_DOMAIN}
export NAMESPACE=${NAMESPACE:-"container-registry"}
export SECRET_NAME=${SECRET_NAME:-"registry-tls"}
export AUTH_USERNAME=${AUTH_USERNAME:-"admin"}
export AUTH_PASSWORD=${AUTH_PASSWORD:-"admin"}

echo "Creating secrets for registry deployment:"
echo "REGISTRY_DOMAIN: $REGISTRY_DOMAIN"
echo "NAMESPACE: $NAMESPACE"
echo "SECRET_NAME: $SECRET_NAME"
echo "AUTH_USERNAME: $AUTH_USERNAME"
echo ""

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create authentication secret (registry-auth)
echo "🔐 Creating authentication secret..."
htpasswd -Bbn $AUTH_USERNAME $AUTH_PASSWORD > auth.htpasswd
kubectl delete secret registry-auth -n $NAMESPACE --ignore-not-found
kubectl create secret generic registry-auth \
  --from-file=htpasswd=auth.htpasswd \
  -n $NAMESPACE
rm -f auth.htpasswd
echo "✅ Authentication secret created"

# Check if TLS certificate exists
if [ -f "/etc/letsencrypt/live/$REGISTRY_DOMAIN/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$REGISTRY_DOMAIN/privkey.pem" ]; then
    echo "🔒 Creating TLS secret from existing certificate..."
    kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found
    kubectl create secret tls $SECRET_NAME \
      --cert="/etc/letsencrypt/live/$REGISTRY_DOMAIN/fullchain.pem" \
      --key="/etc/letsencrypt/live/$REGISTRY_DOMAIN/privkey.pem" \
      -n $NAMESPACE
    echo "✅ TLS secret created from existing certificate"
else
    echo "⚠️  TLS certificate not found at /etc/letsencrypt/live/$REGISTRY_DOMAIN/"
    echo "   Run ./registry-certbot.sh to generate SSL certificate first"
    echo "   Or create a self-signed certificate for testing"
fi

echo ""
echo "🎉 Secrets setup completed!"
echo "You can now run: ./apply.sh" 