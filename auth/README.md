# 🔐 Bật authentication (basic auth)

## ✅ 1. Tạo file `htpasswd` chứa username/password

Trên máy local hoặc VPS, cài `apache2-utils`:

```bash
sudo apt install apache2-utils
```

Tạo file `htpasswd`:

```bash
htpasswd -Bbn <username> <password> > auth.htpasswd
```

Ví dụ:

```bash
htpasswd -Bbn admin mySecurePass > auth.htpasswd
```

> File `auth.htpasswd` sẽ chứa dòng mã hóa như:

```text
admin:$2y$05$Kw1rQCPMyxf82Yxmyt2hxOk5Ey...
```

---

## ✅ 2. Tạo `Secret` trong Kubernetes từ file `auth.htpasswd`:

```bash
microk8s kubectl create secret generic registry-auth \
  --from-file=htpasswd=auth.htpasswd \
  -n container-registry
```

---

## ✅ 3. Sửa lại `Deployment` của Docker Registry để bật authentication

Bạn cần chỉnh lại deployment YAML như sau:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: container-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
          env:
            - name: REGISTRY_AUTH
              value: "htpasswd"
            - name: REGISTRY_AUTH_HTPASSWD_REALM
              value: "Registry Realm"
            - name: REGISTRY_AUTH_HTPASSWD_PATH
              value: "/auth/htpasswd"
          volumeMounts:
            - name: registry-storage
              mountPath: /var/lib/registry
            - name: auth-secret
              mountPath: /auth
              readOnly: true
      volumes:
        - name: registry-storage
          emptyDir: {}
        - name: auth-secret
          secret:
            secretName: registry-auth
```

Sau đó apply lại:

```bash
microk8s kubectl apply -f registry-deployment.yaml
```

---

## ✅ 4. Test login

```bash
docker login registry.local
```

Nhập đúng `username/password` đã tạo → phải thấy:

```text
Login Succeeded
```

---

### ✅ 5. Cập nhật GitHub Actions để push được

Trong repository của bạn trên GitHub:

* Tạo `Secrets`:

  * `REGISTRY_USERNAME` = `admin`
  * `REGISTRY_PASSWORD` = `mySecurePass`

Workflow mẫu:

```yaml
- name: Login to private registry
  run: echo "${{ secrets.REGISTRY_PASSWORD }}" | docker login registry.hnhstudio.site -u ${{ secrets.REGISTRY_USERNAME }} --password-stdin
```
