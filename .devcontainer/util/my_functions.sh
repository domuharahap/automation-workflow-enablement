#!/bin/bash
# ======================================================================
#          ------- Custom Functions -------                            #
#  Space for adding custom functions so each repo can customize as.    # 
#  needed.                                                             #
# ======================================================================

customFunction(){
  printInfoSection "This is a custom function that calculates 1 + 1"

  printInfo "1 + 1 = $(( 1 + 1 ))"

}

# Deploy dtpay — backend (backend-services:8080) + frontend (payment-frontend:80) in namespace dtusecase
# Frontend nginx (ConfigMap: frontend-nginx-config) proxies /api → http://backend-services:8080 within the cluster
deployDtpay() {
  printInfoSection "Deploying dtpay: backend (dtdemos-usecase) + frontend (payment-frontend)"
  kubectl create namespace dtusecase 2>/dev/null || true
  kubectl -n dtusecase apply -f "$FRAMEWORK_APPS_PATH/dtpay/manifests/dtpay.yaml"
  waitForAllReadyPods dtusecase
  registerApp "payment-frontend" "dtusecase" "payment-frontend" 80
  printInfo "dtpay deployed. Frontend URL: $(getAppURL payment-frontend)"
}

undeployDtpay() {
  printInfoSection "Undeploying dtpay"
  unregisterApp "payment-frontend" "dtusecase"
  kubectl delete ns dtusecase --force 2>/dev/null || true
}

# Run JMeter load test against dtpay — one-shot Kubernetes Job, auto-deletes after 60s
# Usage: runJmeterTest [version] [app_url]
#   version: v1.0 (default), v1.2, v1.3, v1.4, v2.0
#   app_url: bare hostname to override JVM_APP_URL (e.g. payment-frontend.dtusecase.svc.cluster.local)
#            defaults to auto-detected ingress URL via getAppURL
runJmeterTest() {
  local version="${1:-v1.0}"
  local app_url_override="${2:-}"
  local valid_versions="v1.0 v1.2 v1.3 v1.4 v2.0"

  if ! echo "$valid_versions" | grep -qw "$version"; then
    printWarn "Unknown version '$version'. Valid options: $valid_versions"
    return 1
  fi

  printInfoSection "Running JMeter load test against dtpay (image: domuharahap/jmeter-tester:$version)"

  local target_url
  if [ -n "$app_url_override" ]; then
    target_url="${app_url_override#http://}"
    target_url="${target_url#https://}"
    printInfo "JMeter target URL (override): $target_url"
  else
    target_url=$(getAppURL "payment-frontend" 2>/dev/null || echo "payment-frontend.127.0.0.1.sslip.io")
    # Strip any protocol prefix — JMeter manifest expects a bare hostname
    target_url="${target_url#http://}"
    target_url="${target_url#https://}"
    printInfo "JMeter target URL (auto-detected): $target_url"
  fi

  kubectl create namespace jmeter 2>/dev/null || true

  # Create dynatrace-creds secret in the jmeter namespace from the codespace env vars.
  # DT_ENVIRONMENT and DT_OPERATOR_TOKEN are injected by Codespaces secrets at startup.
  # Secrets are namespace-scoped — the dynatrace namespace secret cannot be read here.
  kubectl -n jmeter create secret generic dynatrace-creds \
    --from-literal="DT_ENVIRONMENT=${DT_ENVIRONMENT:-}" \
    --from-literal="DT_OPERATOR_TOKEN=${DT_OPERATOR_TOKEN:-}" \
    --dry-run=client -o yaml | kubectl apply -f -

  # Delete any prior run before re-submitting
  kubectl delete job jmeter-tester -n jmeter 2>/dev/null || true

  # Patch image and env vars locally before applying — Job spec.template is immutable
  # once created, so all overrides must be baked in before the first kubectl apply.
  local manifest="$FRAMEWORK_APPS_PATH/jmeter-tester/manifests/jmeter-job.yaml"
  kubectl set image --local -f "$manifest" \
    jmeter-tester="domuharahap/jmeter-tester:$version" -o yaml \
    | kubectl set env --local -f - JVM_APP_URL="$target_url" -o yaml \
    | kubectl apply -n jmeter -f -

  printInfo "JMeter job submitted (version $version, target: $target_url). Waiting for pod to start..."

  # Wait up to 2 minutes for the pod to reach Running state
  local timeout=120
  local elapsed=0
  local pod_phase=""
  local pod_name=""
  while [ $elapsed -lt $timeout ]; do
    pod_name=$(kubectl get pod -n jmeter -l app=jmeter-tester -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$pod_name" ]; then
      pod_phase=$(kubectl get pod -n jmeter "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null)
      if [ "$pod_phase" = "Running" ]; then
        break
      fi
    fi
    sleep 3
    elapsed=$(( elapsed + 3 ))
  done

  if [ "$pod_phase" = "Running" ]; then
    printInfo "JMeter test is RUNNING (pod: $pod_name, target: $target_url)"
    printInfo "Follow logs: kubectl logs -n jmeter $pod_name --follow"
    printInfo "Stop test:   stopJmeterTest"
    printInfo "The job will auto-delete 60s after completion."
  else
    printWarn "Pod did not reach Running state within ${timeout}s (phase: ${pod_phase:-unknown})"
    printWarn "Check: kubectl describe pod -n jmeter -l app=jmeter-tester"
  fi
}

stopJmeterTest() {
  printInfoSection "Stopping JMeter test"
  kubectl delete job jmeter-tester -n jmeter 2>/dev/null || true
  kubectl delete ns jmeter --force 2>/dev/null || true
}





