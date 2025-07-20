#!/bin/bash

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set default values if not provided
export REGISTRY_DOMAIN=${REGISTRY_DOMAIN:-"localhost"}
export NAMESPACE=${NAMESPACE:-"container-registry"}
export SECRET_NAME=${SECRET_NAME:-"registry-tls"}

echo "Creating self-signed certificate for testing:"
echo "REGISTRY_DOMAIN: $REGISTRY_DOMAIN"
echo "NAMESPACE: $NAMESPACE"
echo "SECRET_NAME: $SECRET_NAME"
echo ""

# Create temp directory for certificates
TEMP_CERT_DIR="/tmp/self-signed-$REGISTRY_DOMAIN"
mkdir -p "$TEMP_CERT_DIR"

# Generate self-signed certificate
echo "🔐 Generating self-signed certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$TEMP_CERT_DIR/privkey.pem" \
  -out "$TEMP_CERT_DIR/fullchain.pem" \
  -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Development/CN=$REGISTRY_DOMAIN"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create TLS secret
echo "🔒 Creating TLS secret..."
kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found
kubectl create secret tls $SECRET_NAME \
  --cert="$TEMP_CERT_DIR/fullchain.pem" \
  --key="$TEMP_CERT_DIR/privkey.pem" \
  -n $NAMESPACE

# Clean up
rm -rf "$TEMP_CERT_DIR"

echo "✅ Self-signed certificate created and secret updated!"
echo "⚠️  Note: Self-signed certificates will show security warnings in browsers"
echo "   Use ./registry-certbot.sh for production certificates" 