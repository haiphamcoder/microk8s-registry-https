#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if environment variables are not set
DOMAIN=${DOMAIN:-"registry.hnhstudio.site"}
EMAIL=${EMAIL:-"ngochai285nd@gmail.com"}
NAMESPACE=${NAMESPACE:-"container-registry"}
SECRET_NAME=${SECRET_NAME:-"registry-tls"}
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
TEMP_CERT_DIR="/tmp/certbot-$DOMAIN"

echo "📆 Renewing certificate for $DOMAIN"
sudo certbot renew --standalone --pre-hook "microk8s disable ingress" --post-hook "microk8s enable ingress"

echo "📁 Copy certificate to temp directory"
sudo mkdir -p "$TEMP_CERT_DIR"
sudo cp "$CERT_DIR/fullchain.pem" "$CERT_DIR/privkey.pem" "$TEMP_CERT_DIR/"
sudo chown $(whoami):$(whoami) "$TEMP_CERT_DIR/"*.pem

echo "🔑 Update Kubernetes TLS secret: $SECRET_NAME"
microk8s kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found
microk8s kubectl create secret tls "$SECRET_NAME" \
  --cert="$TEMP_CERT_DIR/fullchain.pem" \
  --key="$TEMP_CERT_DIR/privkey.pem" \
  -n "$NAMESPACE"

echo "🧹 Cleaning up..."
rm -rf "$TEMP_CERT_DIR"

echo "✅ Renew completed for $DOMAIN"
