--8<-- "snippets/dt-enablement.md"

# Cleanup

Remove all workshop resources when you are done.

---

## Remove Simulation Workloads

=== "dtpay (OOM workload)"

    ```bash
    kubectl -n dtpay delete -f .devcontainer/apps/dtpay/manifests/dtpay.yaml
    kubectl delete ns dtpay
    ```

=== "Stuck pod simulation"

    ```bash
    kubectl -n dtusecase delete pod stuck-pod --force --grace-period=0 2>/dev/null || true
    kubectl delete ns dtusecase
    ```

---

## Remove EdgeConnect

```bash
kubectl -n dynatrace delete -f edgeconnect/edgeconnect.yaml
```

!!! tip ""
    After deletion the EdgeConnect entry in **Infrastructure > Kubernetes > EdgeConnect** will disappear automatically once the tunnel closes.

---

## Delete the Codespace

!!! tip "Delete from inside the terminal"
    There is a convenience function loaded in the shell — just type:

    ```bash
    deleteCodespace
    ```

    This triggers deletion of the Codespace from inside the container itself.

Alternatively, go to [https://github.com/codespaces](https://github.com/codespaces){target=_blank} and delete the Codespace from the GitHub UI.

!!! warning "Revoke OAuth credentials"
    After completing the workshop, revoke or delete the OAuth client you created in **Account Management > Identity & Access Management > OAuth Clients** to avoid leaving unused credentials active.

<div class="grid cards" markdown>
- [Resources :octicons-arrow-right-24:](resources.md)
</div>
