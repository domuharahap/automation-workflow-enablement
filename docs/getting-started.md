--8<-- "snippets/dt-enablement.md"

# Getting Started

## Prerequisites

Before launching the Codespace, ensure you have everything in place.

!!! warning "Requirements"
    - A **Dynatrace Platform** environment (SaaS or Managed) with the Dynatrace Operator installed on the cluster
    - **GitHub Codespaces** access (or a local Dev Container)
    - All **six Codespace secrets** populated (see tables below)

### Required Secrets

**Dynatrace credentials:**

| Secret | Description |
|---|---|
| `DT_ENVIRONMENT` | Your DT platform URL, e.g. `https://abc123.apps.dynatrace.com` |
| `DT_OPERATOR_TOKEN` | Operator token from DT UI (auto-created when adding a cluster) |
| `DT_INGEST_TOKEN` | Ingest token (logs, metrics, traces) |

**OAuth credentials (for EdgeConnect provisioning):**

| Secret | Description |
|---|---|
| `DT_CLIENT_ID` | OAuth Client ID — format: `dt0s02.XXXX` |
| `DT_CLIENT_SECRET` | OAuth Client Secret paired with `DT_CLIENT_ID` |
| `DT_URN_ACCOUNT` | Account URN — format: `urn:dtaccount:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

---

## Part 1 — Create the OAuth Client

The EdgeConnect CRD uses OAuth for provisioning. You need a dedicated OAuth client in Dynatrace before deploying.

!!! example "Step-by-step"

    1. Open your Dynatrace environment and navigate to **Account Management** (top-right user menu)
    2. Go to **Identity & Access Management > OAuth Clients**
    3. Click **Create client**
    4. Give it a name, e.g. `edgeconnect-k8s-workshop`
    5. Under **Scopes**, add the following:
        - `automation:workflows:run`
        - `automation:workflows:read`
        - `automation:workflows:write`
        - `edge:connect:provision`
        - `edge:connect:read`
    6. Click **Create** and copy both the **Client ID** (`dt0s02.XXXX`) and **Client Secret**
    7. Copy the **Account URN** from Account Management — format: `urn:dtaccount:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

!!! tip "Save before you launch"
    Store these values as Codespace secrets (`DT_CLIENT_ID`, `DT_CLIENT_SECRET`, `DT_URN_ACCOUNT`) **before** creating the Codespace — the post-create script reads them at startup.

---

## Part 2 — Launch the Codespace

!!! example "Step-by-step"

    1. Open this repository on GitHub and click **Code > Codespaces > Create codespace on main**
    2. GitHub will prompt you to confirm secrets — verify all six are populated:

        | Secret | Status |
        |---|---|
        | `DT_ENVIRONMENT` | :material-check-circle:{ .green } required |
        | `DT_OPERATOR_TOKEN` | :material-check-circle:{ .green } required |
        | `DT_INGEST_TOKEN` | :material-check-circle:{ .green } required |
        | `DT_CLIENT_ID` | :material-check-circle:{ .green } required |
        | `DT_CLIENT_SECRET` | :material-check-circle:{ .green } required |
        | `DT_URN_ACCOUNT` | :material-check-circle:{ .green } required |

    3. Wait for the Codespace to finish initializing — the post-create script installs the Kubernetes cluster and deploys the Dynatrace Operator automatically
    4. Open the **Terminal** panel in VS Code (`View → Open View → Terminal`)
    5. Verify the cluster and Dynatrace Operator are running:

    ```bash
    kubectl get nodes
    kubectl get pods -n dynatrace
    ```

!!! tip "What the post-create script does"
    The `post-create.sh` script automatically:

    - Creates a K3d/Kind Kubernetes cluster
    - Deploys the Dynatrace Operator via Helm
    - Applies your credentials as a Dynakube secret
    - Exposes the MkDocs documentation on port 8000

<div class="grid cards" markdown>
- [Continue to Deployment :octicons-arrow-right-24:](edgeconnect-deployment.md)
</div>
