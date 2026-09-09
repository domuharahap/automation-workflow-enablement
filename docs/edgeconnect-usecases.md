--8<-- "snippets/dt-enablement.md"

# Use Cases

With EdgeConnect deployed and both workflows activated, run the two automation scenarios below.

---

## Use Case 1 — Stuck Pod Cleanup (Zero-Touch)

### Configure anomaly detection

!!! warning "Demo preparation"
    Before triggering the scenario, change the Kubernetes anomaly detection sensitivity so the workflow fires quickly during the demo.

!!! example ""
    ![Pod stack anomaly settings](img/pod-stack.png)

### Trigger the stuck pod

Delete the pod — it will enter `Terminating` state and hang for 5 minutes due to its `preStop` hook:

```bash
kubectl delete pod stuck-pod -n dtusecase
kubectl -n dtusecase get pod stuck-pod -w
```

### Watch the zero-touch workflow execute

!!! success "Expected flow"
    1. Davis AI detects **Pods stuck in terminating**
    2. The `K8s Pod Cleanup` workflow fires **automatically** — no approval required
    3. The `delete_pod` task force-deletes the stuck pod via the EdgeConnect K8s connector
    4. Davis AI closes the problem

**Validate in Dynatrace:**

- Navigate to **Automations > Workflows** → check the `K8s Pod Cleanup` execution history
- Confirm the pod is gone:

```bash
kubectl -n dtusecase get pod stuck-pod
```

!!! example ""
    ![Workflow run termination success](img/workflow-run-termination-success.png)

---

## Use Case 2 — OOM Remediation (Approval-Gated)

### Trigger the OOM

!!! example "Step-by-step"

    1. In VS Code, open **Ports** → find the `dtpay` frontend port
    2. Open the exposed URL in a browser:

    ```
    https://<EXTERNAL-IP>/usecase.html
    ```

!!! example ""
    ![Portal simulation dtpay](img/portal-simulation-dtpay.png)

!!! example "Step-by-step (continued)"

    3. Click the trigger button on the page to start the memory allocation loop
    4. Watch the pod crash in the terminal:

    ```bash
    kubectl -n dtpay get pods -w
    ```

### Watch the approval-gated workflow execute

!!! success "Expected flow"
    1. Davis AI detects **Memory resources exhausted**
    2. The `OOM Remediation` workflow fires:
        - :material-slack: **Slack notification** is sent to your configured channel
        - :material-email: **Approval email** is sent to the configured approver
    3. Open the approval link in the email
    4. Click **Approve**
    5. The workflow executes:
        ```bash
        kubectl rollout restart deployment/dtdemo-usecase -n dtpay
        ```
    6. A follow-up :material-slack: **Slack confirmation** is sent

**Validate in Dynatrace:**

- Navigate to **Automations > Workflows** → check execution history and individual task states
- Navigate to **Infrastructure > Kubernetes** → verify the deployment restarted successfully

<div class="grid cards" markdown>
- [Continue to Cleanup :octicons-arrow-right-24:](cleanup.md)
</div>
