#!/bin/bash

set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if environment variables are not set
REGISTRY_DOMAIN=${REGISTRY_DOMAIN}
EMAIL=${EMAIL}
NAMESPACE=${NAMESPACE}
SECRET_NAME=${SECRET_NAME}
TEMP_CERT_DIR="/tmp/certbot-$REGISTRY_DOMAIN"
CERT_DIR="/etc/letsencrypt/live/$REGISTRY_DOMAIN"

echo "🚫 Disable ingress"
microk8s disable ingress

echo "🔐 Get certificate"
sudo certbot certonly --standalone -d $REGISTRY_DOMAIN --agree-tos --email $EMAIL --non-interactive

echo "📁 Copy certificate to temp directory"
sudo mkdir -p "$TEMP_CERT_DIR"
sudo cp "$CERT_DIR/fullchain.pem" "$CERT_DIR/privkey.pem" "$TEMP_CERT_DIR/"
sudo chown $(whoami):$(whoami) "$TEMP_CERT_DIR/"*.pem

echo "🔑 Create Kubernetes TLS secret: $SECRET_NAME (namespace: $NAMESPACE)"
microk8s kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found
microk8s kubectl create secret tls "$SECRET_NAME" \
  --cert="$TEMP_CERT_DIR/fullchain.pem" \
  --key="$TEMP_CERT_DIR/privkey.pem" \
  -n "$NAMESPACE"

echo "🚀 Enable ingress"
microk8s enable ingress

echo "🧹 Remove temp directory: $TEMP_CERT_DIR"
rm -rf "$TEMP_CERT_DIR"

echo "✅ Done! TLS is ready to use for $REGISTRY_DOMAIN"