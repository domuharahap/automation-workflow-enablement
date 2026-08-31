# dtpay — Payment Use Case

dtpay is a Kubernetes-native payment demo application used for observability workshops. It consists of a Java Spring Boot backend and a React/TypeScript frontend served by nginx, deployed together in the `dtusecase` namespace.

---

## Architecture

```
Browser
  │
  ▼
payment-frontend (nginx, port 80)
  │  nginx ConfigMap: frontend-nginx-config
  │  location /        → serves React SPA (static files)
  │  location /api     → proxy_pass http://backend-services:8080
  │
  ▼
backend-services (Java Spring Boot, port 8080)
```

The nginx ConfigMap (`frontend-nginx-config`) handles all API routing inside the cluster. The browser never talks directly to the backend — it calls `/api/*` paths and nginx forwards them to `backend-services:8080`.

---

## Kubernetes Resources

All manifests are in [.devcontainer/apps/dtpay/manifests/dtpay.yaml](.devcontainer/apps/dtpay/manifests/dtpay.yaml).

| Resource | Name | Details |
|---|---|---|
| Deployment | `backend-usecase` | Java Spring Boot — `domuharahap/dtdemo-usecase:backend.x.x` |
| Service | `backend-services` | ClusterIP, port 8080 |
| ConfigMap | `frontend-nginx-config` | nginx `default.conf` with `/api` proxy rule |
| Deployment | `payment-frontend` | nginx + React SPA — `domuharahap/dtdemo-usecase:frontend.x.x` |
| Service | `payment-frontend` | ClusterIP, port 80 |

### Backend environment variables

| Variable | Value | Purpose |
|---|---|---|
| `JAVA_OPTS` | `-Xms256m -Xmx256m -XX:+ExitOnOutOfMemoryError` | JVM heap sizing |

### Resource limits

| Component | CPU request | CPU limit | Memory request | Memory limit |
|---|---|---|---|---|
| Backend | 250m | 500m | 256Mi | 512Mi |

---

## Deploy / Undeploy

Use the framework shell functions (sourced automatically in every terminal):

```bash
# Deploy dtpay into namespace dtusecase
deployDtpay

# Undeploy and delete the namespace
undeployDtpay

# Or via the menu
deployApp 5          # by number
deployApp e          # by letter
deployApp dtpay      # by name

deployApp 5 -d       # undeploy
```

`deployDtpay` creates the `dtusecase` namespace, applies all manifests, waits for pods to be ready, and registers the frontend with the ingress so it is accessible at:

- `payment-frontend.<ip>.sslip.io` (VS Code / local / remote VM)
- `payment-frontend.<hostname>` (CI / host-header curl)
- Catch-all (GitHub Codespaces port forwarding)

---

## Docker Images

| Image | Tag pattern | Source repo |
|---|---|---|
| `domuharahap/dtdemo-usecase` | `backend.x.x` | Java Spring Boot backend |
| `domuharahap/dtdemo-usecase` | `frontend.x.x` | React/TypeScript + nginx |

The frontend image is built with the nginx `default.conf` baked in and overridden at deploy time by the `frontend-nginx-config` ConfigMap mounted at `/etc/nginx/conf.d/default.conf`.

---

## nginx Proxy Configuration

The ConfigMap defines a single `server` block:

```nginx
server {
    listen 80;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html;   # SPA fallback
    }

    location /api {
        proxy_pass http://backend-services:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    error_page 500 502 503 504 /50x.html;
}
```

All React client-side routes are handled by `try_files … /index.html`. All `/api/*` calls are forwarded cluster-internally to `backend-services:8080` — the backend hostname is never exposed to the browser.

---

## Load Testing

Pair dtpay with the JMeter tester to generate realistic traffic. See [jmeter.md](jmeter.md) for full usage.

```bash
# Run a JMeter load test against the deployed dtpay frontend
runJmeterTest        # defaults to v1.0
runJmeterTest v1.4   # with Dynatrace BizEvents

# Stop a running test
stopJmeterTest
```
