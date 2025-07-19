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
  --cert=./certs/tls.crt \
  --key=./certs/tls.key \
  -n container-registry
```

# Login vào registry
docker login registry.local -u admin -p admin

# Tag image cho registry
docker tag <image>:<tag> registry.local/<repository>/<image>:<tag>

# Push image
docker push registry.local/<repository>/<image>:<tag>

# Pull image
docker pull registry.local/<repository>/<image>:<tag>

# Xem danh sách repositories
curl -k -u admin:admin https://registry.local/v2/_catalog

# Xem tags của repository
curl -k -u admin:admin https://registry.local/v2/<repository>/<image>/tags/list