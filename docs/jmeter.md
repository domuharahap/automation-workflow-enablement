# JMeter Load Tester

The JMeter tester is a containerized Apache JMeter load generator designed to run performance tests against the dtpay payment application with built-in Dynatrace observability integration.

Source: [github.com/domuharahap/jmeter-tester](https://github.com/domuharahap/jmeter-tester)

---

## Overview

The tester runs as a one-shot Kubernetes `Job` in the `jmeter` namespace. The job auto-deletes 60 seconds after completion (`ttlSecondsAfterFinished: 60`). Each version adds deeper Dynatrace integration on top of the previous.

**Test scenarios (all versions):**

| Scenario | Request | Details |
|---|---|---|
| Home Page | `GET /` | Loads the React SPA |
| Payment | `POST /api/payment` | Randomized amount, method, name, and user ID |

---

## Versions

| Version | Image | What's new |
|---|---|---|
| `v1.0` | `domuharahap/jmeter-tester:v1.0` | Basic load test — results visible in DT APM traces |
| `v1.2` | `domuharahap/jmeter-tester:v1.2` | Adds `x-dynatrace-test` request header for test marking |
| `v1.3` | `domuharahap/jmeter-tester:v1.3` | BizEvents at test start and end with full summary stats |
| `v1.4` | `domuharahap/jmeter-tester:v1.4` | v1.3 + live stats BizEvent every 30 s |
| `v2.0` | `domuharahap/jmeter-tester:v2.0` | Extended scenarios |

### v1.2 — Dynatrace Test Marking

Adds the standard `x-dynatrace-test` header to every request:

```
x-dynatrace-test: LTN=<test-name>;LSN=<scenario>;TSN=<sampler>;VU=<thread>;RUN=<time>;RID=<run-id>
```

### v1.3 — BizEvents: Start & End

Sends two Dynatrace Business Events:

| Event | When | Payload |
|---|---|---|
| `com.jmeter.test.start` | Before test (setUp group) | Test metadata |
| `com.jmeter.test.summary` | After test (tearDown group) | avg/min/max latency, error %, throughput |

### v1.4 — BizEvents: Live Stats

Extends v1.3 with a background thread group that sends incremental stats every 30 s.  
Interval is configurable via `STATS_INTERVAL_SEC` (default: `30`).

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `JVM_THREADS` | `50` | Concurrent virtual users |
| `JVM_LOOPS` | `-1` | Iterations per thread (`-1` = run for full duration) |
| `JVM_DURATION` | `600` | Test duration in seconds |
| `JVM_APP_URL` | `dtpay.127.0.0.1.sslip.io` | Target domain — no protocol or port prefix |
| `JVM_DT_URL` | *(required)* | Dynatrace environment URL |
| `JVM_DT_TOKEN` | *(required)* | DT API token with `bizevents.ingest` scope |

`JVM_DT_URL` and `JVM_DT_TOKEN` are read from a Kubernetes Secret (`dynatrace-creds` in the `jmeter` namespace). The framework functions create this secret automatically from `DT_ENVIRONMENT` and `DT_OPERATOR_TOKEN`.

---

## Running via Framework Functions

The framework provides shell functions for the full lifecycle. Source the framework first if not already done:

```bash
source .devcontainer/util/source_framework.sh
```

### Start a test

```bash
runJmeterTest           # v1.0 (default)
runJmeterTest v1.2      # with DT test marking
runJmeterTest v1.3      # with BizEvents summary
runJmeterTest v1.4      # with live BizEvents
runJmeterTest v2.0      # extended scenarios
```

`runJmeterTest` will:

1. Detect the dtpay ingress URL automatically via `getAppURL payment-frontend`
2. Create the `jmeter` namespace
3. Create/update the `dynatrace-creds` secret from `DT_ENVIRONMENT` and `DT_OPERATOR_TOKEN`
4. Delete any prior `jmeter-tester` job
5. Apply [.devcontainer/apps/jmeter-tester/manifests/jmeter-job.yaml](.devcontainer/apps/jmeter-tester/manifests/jmeter-job.yaml)
6. Patch the image version and `JVM_APP_URL` at runtime
7. Wait up to 15 minutes for job completion

### Stop a test

```bash
stopJmeterTest    # deletes the job and jmeter namespace
```

### Check logs

```bash
kubectl logs -n jmeter -l app=jmeter-tester --follow
```

---

## Kubernetes Manifest

The base Job manifest is at [.devcontainer/apps/jmeter-tester/manifests/jmeter-job.yaml](.devcontainer/apps/jmeter-tester/manifests/jmeter-job.yaml).

Key settings:

```yaml
spec:
  ttlSecondsAfterFinished: 60   # auto-cleanup
  backoffLimit: 0               # no retries on failure
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: jmeter-tester
          image: domuharahap/jmeter-tester:v1.0   # patched at runtime
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "2Gi"
              cpu: "1000m"
```

The `JVM_APP_URL` and image tag are overridden at runtime by `kubectl set env` and `kubectl set image` inside `runJmeterTest`.

---

## Dynatrace Setup

**Required token scope:** `bizevents.ingest` (needed for v1.3+)

**DQL query to compare test runs:**

```dql
fetch bizevents
| filter event.type == "com.jmeter.test.summary"
| sort timestamp desc
```

---

## Tech Stack

- Apache JMeter 5.6.3 — headless, non-GUI mode
- Java 17 (OpenJDK, Alpine-based image)
- Groovy scripts for random data generation and BizEvent publishing
- Kubernetes Job for one-shot execution
- Dynatrace Business Events API v2
