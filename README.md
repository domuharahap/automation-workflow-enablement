<!-- markdownlint-disable-next-line -->
# <img src="https://cdn.bfldr.com/B686QPH3/at/w5hnjzb32k5wcrcxnwcx4ckg/Dynatrace_signet_RGB_HTML.svg?auto=webp&format=pngg" alt="DT logo" width="45"> EdgeConnect — Automation Workflow Enablement

[![Dynatrace](https://img.shields.io/badge/Dynatrace-Automation-purple?logo=dynatrace&logoColor=white)](https://github.com/domuharahap/Dynatrace-EdgeConnect)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?color=green)](LICENSE)

___

A hands-on automation workshop built on the [Dynatrace Enablement Framework](https://dynatrace-wwse.github.io/codespaces-framework). This repo demonstrates how to use **Dynatrace EdgeConnect** to enable secure Kubernetes automation — letting Dynatrace Workflows remediate incidents (OOM crashes, stuck pods) via the K8s API without exposing your cluster to the internet.

<p align="center">
  <img src="docs/img/framework_banner.png" alt="DT Enablement">
</p>

___

## What's in this repo

| Component | Description |
|---|---|
| **EdgeConnect** | Kubernetes manifests to deploy EdgeConnect with OAuth, RBAC, and `kubernetesAutomation` enabled |
| **Simulation workloads** | OOM demo app and stuck-pod simulation to trigger automation scenarios |
| **Automation workflows** | Dynatrace Workflow JSON exports for OOM remediation (approval-gated) and pod cleanup (zero-touch) |
| **Framework functions** | Core shell library for cluster management, ingress, app registry, and Dynatrace credential handling |

## Architecture

```
Dynatrace Platform (Davis AI)
  │
  │  detects event (OOM / stuck pod)
  ▼
Automation Workflow Engine
  │
  │  executes K8s action via EdgeConnect tunnel
  ▼
EdgeConnect (running in-cluster, dynatrace namespace)
  │
  │  forwards kubectl command to K8s API server
  ▼
Kubernetes Cluster (dtusecase / default namespace)
  └── stuck-pod                  ← pod termination use case
  └── dtdemo-usecase deployment  ← OOM use case
```

## Use Cases

| # | Use Case | Trigger | Remediation | Mode |
|---|---|---|---|---|
| 1 | Stuck Terminating Pod | Pod stuck in `Terminating` > 5 min | Force-delete via K8s API | Zero-touch |
| 2 | OOM / Memory Exhausted | App hits memory limit and crashes | `kubectl rollout restart` deployment | Approval-gated (Slack + email) |


## Quick Start

```bash
# 1. Open in GitHub Codespaces — set all 6 secrets before launching
#    DT_ENVIRONMENT, DT_OPERATOR_TOKEN, DT_INGEST_TOKEN
#    DT_CLIENT_ID, DT_CLIENT_SECRET, DT_URN_ACCOUNT

# 2. Verify the cluster and Dynatrace Operator are running
kubectl get nodes
kubectl get pods -n dynatrace

# 3. Deploy EdgeConnect
cd .devcontainer/apps/edgeconnect
kubectl apply -f edgeconnect.yaml

# 4. Deploy the simulation workloads
kubectl apply -f podtermination-usecase.yaml
kubectl apply -f oom-usecase-deployment.yaml
kubectl apply -f oom-usecase-svc.yaml

# 5. Import and activate workflows in Dynatrace UI
#    → Automations > Workflows > Import workflow
#    use-case-automation-oom-remediation-w-k8s.workflow.json
#    use-case-automation-k8s-pod-cleanup.workflow.json
```

See [docs/edgeconnect-workshop.md](docs/edgeconnect-workshop.md) for the full step-by-step workshop guide.

## Required Codespace Secrets

| Secret | Description |
|---|---|
| `DT_ENVIRONMENT` | Dynatrace platform URL, e.g. `https://abc123.apps.dynatrace.com` |
| `DT_OPERATOR_TOKEN` | Operator token (auto-created when adding a cluster in DT UI) |
| `DT_INGEST_TOKEN` | Ingest token for logs, metrics, and traces |
| `DT_CLIENT_ID` | OAuth Client ID for EdgeConnect provisioning — format: `dt0s02.XXXX` |
| `DT_CLIENT_SECRET` | OAuth Client Secret paired with `DT_CLIENT_ID` |
| `DT_URN_ACCOUNT` | Account URN for OAuth resource scope — format: `urn:dtaccount:xxxx-xxxx` |

## Documentation

| Doc | Description |
|---|---|
| [EdgeConnect Workshop](docs/edgeconnect-workshop.md) | Full step-by-step hands-on workshop guide |
| [Framework functions](docs/functions.md) | Full shell function reference |
| [Framework architecture](docs/framework.md) | Versioned pull model, file classification, image tiers |

## Source Repos

- EdgeConnect manifests & workflows: [github.com/domuharahap/Dynatrace-EdgeConnect](https://github.com/domuharahap/Dynatrace-EdgeConnect)
- OOM demo app image: `domuharahap/dtdemo-usecase:2.2`
- Framework base: [github.com/dynatrace-wwse/codespaces-framework](https://github.com/dynatrace-wwse/codespaces-framework)
