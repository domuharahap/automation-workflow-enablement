--8<-- "snippets/dt-enablement.md"

# EdgeConnect Automation Workshop

!!! example ""
    ![EdgeConnect Workshop Banner](img/framework_banner.png){ align=center }

## About this Workshop

This hands-on workshop demonstrates how to use **Dynatrace EdgeConnect** to enable secure Kubernetes automation — allowing Dynatrace Workflows to execute `kubectl` actions against your cluster without exposing it to the internet.

EdgeConnect acts as a **secure reverse-tunnel** between Dynatrace and your Kubernetes cluster. Once deployed, the Dynatrace Automation Engine can execute Kubernetes actions (restart deployments, delete stuck pods) via the K8s API — triggered by Davis AI events, with optional human-approval gates.

!!! info "Source Repository"
    [:material-github: github.com/domuharahap/Dynatrace-EdgeConnect](https://github.com/domuharahap/Dynatrace-EdgeConnect)

---

## What You'll Learn

By the end of this workshop you will be able to:

- [x] Deploy **Dynatrace EdgeConnect** on a Kubernetes cluster using a single shell function
- [x] Configure **RBAC** with least-privilege access for automation
- [x] Set up two production-grade **Automation Workflows** driven by Davis AI
- [x] Execute **zero-touch** pod remediation when pods get stuck in `Terminating`
- [x] Implement an **approval-gated** OOM restart workflow with Slack notifications

---

## Use Cases

| # | Use Case | Trigger | Remediation | Mode |
|---|---|---|---|---|
| 1 | Stuck Terminating Pod | Pod stuck in `Terminating` > 5 min | Force-delete via K8s API | :material-robot: Zero-touch |
| 2 | OOM / Memory Exhausted | App hits memory limit and crashes | `kubectl rollout restart` | :material-account-check: Approval-gated |

---

## Architecture

```
Dynatrace Platform
      │  (Automation Workflows triggered by Davis AI)
      │
      ▼
EdgeConnect (reverse-tunnel, inside your cluster)
      │  (forwards kubectl API calls)
      │
      ▼
Kubernetes API Server
      │
      ├── dtusecase namespace  (stuck-pod simulation)
      └── dtpay namespace      (OOM simulation)
```

---

## Workshop Structure

| Section | Content |
|---|---|
| [Getting Started](getting-started.md) | Prerequisites, OAuth Client setup, Codespace launch |
| [Deployment](edgeconnect-deployment.md) | Deploy EdgeConnect, simulation workloads, and import workflows |
| [Use Cases](edgeconnect-usecases.md) | Run and validate both automation scenarios |
| [Cleanup](cleanup.md) | Remove all workshop resources |
| [Resources](resources.md) | Reference links and further reading |

<div class="grid cards" markdown>
- [Let's get started :octicons-arrow-right-24:](getting-started.md)
</div>
