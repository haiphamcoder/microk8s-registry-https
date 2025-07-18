# Local Self-Signed

```bash
mkdir certs
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout ./certs/tls.key \
  -out ./certs/tls.crt \
  -subj "/CN=registry.local" \
  -addext "subjectAltName=DNS:registry.local"
```

microk8s kubectl apply -f registry-deployment.yaml

```bash
microk8s kubectl create namespace container-registry

microk8s kubectl create secret tls registry-tls \
  --cert=~/certs/tls.crt \
  --key=~/certs/tls.key \
  -n container-registry
```

