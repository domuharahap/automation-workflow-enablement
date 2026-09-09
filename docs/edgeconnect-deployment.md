--8<-- "snippets/dt-enablement.md"

# Deployment

This section covers deploying EdgeConnect, standing up the simulation workloads, and importing the automation workflows into Dynatrace.

---

## Part 3 — Deploy EdgeConnect (RBAC + CRD)

The `deployEdgeConnect` function reads your credentials directly from environment variables set as Codespace secrets (`DT_CLIENT_ID`, `DT_CLIENT_SECRET`, `DT_ENVIRONMENT`, `DT_URN_ACCOUNT`), substitutes them into the manifest in memory, and applies everything in one step — no manual file editing required.

### Step 3.1 — Deploy EdgeConnect

```bash
deployEdgeConnect
```

!!! info "What this function does"
    1. Validates that all four required environment variables are set
    2. Strips any `https://` prefix from `DT_ENVIRONMENT` (the `apiServer` field requires hostname only)
    3. Substitutes credentials into the manifest in-memory via `sed` — nothing is written to disk
    4. Applies the manifest via `kubectl apply`, creating:
        - `ServiceAccount` (`edgeconnect-sa`) in the `dynatrace` namespace
        - `Role` (`edgeconnect-role`) with least-privilege pod/deployment/configmap/job/PVC access
        - `RoleBinding` (`edgeconnect-rb`) binding the role to the service account
        - `Secret` containing your OAuth credentials
        - `EdgeConnect` CRD resource enabling `kubernetesAutomation`
    5. Prints the EdgeConnect resource and pod status immediately after apply

### Step 3.2 — Verify EdgeConnect is running

```bash
kubectl get edgeconnect -n dynatrace
kubectl get pods -n dynatrace | grep edgeconnect
```

!!! tip ""
    The EdgeConnect pod should reach `Running` state within ~60 seconds. It registers itself in the Dynatrace UI automatically.

!!! example ""
    ![EdgeConnect Deployment Status](img/edgeconnect-deployment-status.png)

### Step 3.3 — Confirm registration in Dynatrace

!!! example "Step-by-step"

    1. Open your Dynatrace environment
    2. Navigate to **Infrastructure > Kubernetes > EdgeConnect**
    3. You should see `k8s-workshop` listed with status **Online**

!!! example ""
    ![Dynatrace EdgeConnect Status](img/dynatrace-edgeconnect-status.png)

!!! example "Step-by-step (continued)"

    4. Navigate to **Infrastructure > Kubernetes > k8s-workshop**
    5. Validate that `k8s-workshop` shows status **Connected**

!!! example ""
    ![Dynatrace K8s Validate Status](img/dynatrace-k8s-validate-status.png)

---

## Part 4 — Deploy the Simulation Workloads

These workloads intentionally trigger the failure scenarios that the automation workflows will remediate.

### Step 4.1 — Stuck pod simulation

```bash
cd .devcontainer/apps
kubectl create ns dtusecase
kubectl -n dtusecase apply -f podtermination/podtermination-usecase.yaml
```

!!! info ""
    This creates a `busybox` pod named `stuck-pod` with a `preStop` hook that sleeps 300 seconds, simulating a pod stuck in `Terminating` state.

### Step 4.2 — dtpay application (OOM simulation)

```bash
deployDtpay
```

!!! info ""
    This deploys the `dtpay` applications in the `dtpay` namespace. The container is configured with:

    - Memory limit: `512Mi`
    - JVM flag: `-XX:+ExitOnOutOfMemoryError`
    - A `/usecase.html` load endpoint that allocates memory until the pod crashes

### Step 4.3 — Verify workloads are running

```bash
kubectl get all -n dtusecase
kubectl get all -n dtpay
kubectl -n dtusecase get pod stuck-pod
```

---

## Part 5 — Import the Automation Workflows

### Step 5.1 — Import workflow files

!!! example "Step-by-step"

    1. In the Dynatrace UI, navigate to **Automations > Workflows**
    2. Click **Import workflow** (top-right corner)
    3. Import `use-case-automation-k8s-pod-cleanup.workflow.json`
    4. Import `use-case-automation-oom-remediation-w-k8s.workflow.json`

    These JSON files are available in the [reference repository](https://github.com/domuharahap/Dynatrace-EdgeConnect).

### Step 5.2 — Configure the pod cleanup workflow

Open **`[use-case automation] - K8s Pod Cleanup`**:

!!! example "Step-by-step"

    1. Click the **`delete_pod`** task
    2. Confirm the EdgeConnect instance is set to `k8s-workshop`
    3. Save and **Activate** the workflow

!!! example ""
    ![Workflow pod stack](img/workflow-pod-stack.png)

### Step 5.3 — Configure the OOM workflow

Open **`[use case automation] oom remediation w k8s`**:

!!! example "Step-by-step"

    1. Click the **`send_notification`** task → update the Slack connection and channel to your own
    2. Click the **`request_approval`** task → update the approver email/user ID
    3. Click the **`restart_deployment`** task → confirm the EdgeConnect instance is set to `k8s-workshop`
    4. Save and **Activate** the workflow

!!! tip "All set"
    With both workflows imported and activated, the environment is ready. Proceed to the Use Cases section to trigger and validate the automation scenarios.

<div class="grid cards" markdown>
- [Continue to Use Cases :octicons-arrow-right-24:](edgeconnect-usecases.md)
</div>
