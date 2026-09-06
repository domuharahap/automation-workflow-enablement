<!-- markdownlint-disable-next-line -->
# <img src="https://cdn.bfldr.com/B686QPH3/at/w5hnjzb32k5wcrcxnwcx4ckg/Dynatrace_signet_RGB_HTML.svg?auto=webp&format=pngg" alt="DT logo" width="45"> dtpay — Payment Observability Workshop

[![Dynatrace](https://img.shields.io/badge/Dynatrace-Observability-purple?logo=dynatrace&logoColor=white)](https://github.com/domuharahap/dynatrace-jmeter-enablement)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?color=green)](https://github.com/domuharahap/dynatrace-jmeter-enablement/blob/main/LICENSE)
[![Docker](https://img.shields.io/badge/Image-shinojosa%2Fdt--enablement-blue?logo=docker)](https://hub.docker.com/r/domuharahap/jmeter-tester)

___

A hands-on observability workshop built on the [Dynatrace Enablement Framework](https://dynatrace-wwse.github.io/codespaces-framework). This repo demonstrates end-to-end observability of a Kubernetes-native payment application (**dtpay**) using Dynatrace, with realistic load generation powered by a versioned **JMeter** tester that sends Business Events directly to Dynatrace.

<p align="center">
  <img src="docs/img/framework_banner.png" alt="DT Enablement">
</p>

___

## What's in this repo

| Component | Description |
|---|---|
| **dtpay** | Payment demo app — Java Spring Boot backend + React/nginx frontend, deployed to Kubernetes (`dtusecase` namespace) |
| **JMeter tester** | Containerized Apache JMeter (v1.0 – v2.0) targeting dtpay with progressive Dynatrace integration |
| **Framework functions** | Core shell library for cluster management, ingress, app registry, and Dynatrace credential handling |
| **my_functions.sh** | Repo-specific functions: `deployDtpay`, `undeployDtpay`, `runJmeterTest`, `stopJmeterTest` |

## Architecture

```
Browser
  │
  ▼
payment-frontend (nginx, port 80)    ← registered at payment-frontend.<ip>.sslip.io
  │  nginx ConfigMap proxies:
  │  location /api → http://backend-services:8080
  │
  ▼
backend-services (Java Spring Boot, port 8080)
```

JMeter runs as a Kubernetes Job in the `jmeter` namespace and sends load to the dtpay ingress URL, with Dynatrace Business Events for observability of test runs.

## Quick start

```bash
# 1. Open in GitHub Codespaces or VS Code Dev Container
# 2. Start a Kubernetes cluster
startCluster # Skip this steps as the cluster has automatic start

# 3. Deploy dtpay
deployDtpay

# 4. Run a JMeter load test against dtpay
runJmeterTest v1.4 your-codespaces-generated-id-80.app.github.dev  # v1.0 | v1.2 | v1.3 | v2.0

# 5. Stop the test
stopJmeterTest

# 6. Tear down dtpay
undeployDtpay
```

Or use the interactive deploy menu:

```bash
deployApp           # shows the full menu
deployApp 5         # deploy dtpay
deployApp 5 -d      # undeploy dtpay
```

## Available apps

| # | Name | Notes |
|---|---|---|
| 1 | bugzapper | Lightweight debug game |
| 2 | todoapp | Simple Java todo app |
| 3 | unguard | Security demo (AMD64 only) |
| 4 | opentelemetry-demo | CNCF upstream OTel demo |
| **5** | **dtpay** | **Payment use case — primary focus of this repo** |

## JMeter versions

| Version | Image | What's new |
|---|---|---|
| v1.0 | `domuharahap/jmeter-tester:v1.0` | Basic load test |
| v1.2 | `domuharahap/jmeter-tester:v1.2` | `x-dynatrace-test` request marking header |
| v1.3 | `domuharahap/jmeter-tester:v1.3` | BizEvents at test start and end |
| v2.0 | `domuharahap/jmeter-tester:v2.0` | v2.0 + live stats BizEvent every 30 s & Extended scenarios |

## Documentation

| Doc | Description |
|---|---|
| [dtpay](docs/dtpay.md) | Architecture, Kubernetes resources, nginx config, deploy steps |
| [JMeter](docs/jmeter.md) | Version matrix, config variables, BizEvents, DQL queries |
| [Framework functions](docs/functions.md) | Full shell function reference |
| [Framework architecture](docs/framework.md) | Versioned pull model, file classification, image tiers |

## Docker images

| Image | Tag | Description |
|---|---|---|
| `domuharahap/dtdemo-usecase` | `backend.x.x` | Java Spring Boot payment backend |
| `domuharahap/dtdemo-usecase` | `frontend.x.x` | React UI + nginx reverse proxy |
| `domuharahap/jmeter-tester` | `v1.0` – `v2.0` | JMeter load tester with Dynatrace integration |

## Source repos

- Frontend: [github.com/domuharahap/sampleusecase-dtpay-frontend](https://github.com/domuharahap/sampleusecase-dtpay-frontend)
- JMeter: [github.com/domuharahap/jmeter-tester](https://github.com/domuharahap/jmeter-tester)
- Framework base: [github.com/dynatrace-wwse/codespaces-framework](https://github.com/dynatrace-wwse/codespaces-framework)
