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

# Deploy dtpay — backend (dtdemos-usecase:8080) + frontend (payment-frontend:80) in namespace dtusecase
# Frontend nginx proxies /api/ → http://dtdemos-usecase:8080 within the cluster
deployDtpay() {
  printInfoSection "Deploying dtpay: backend (dtdemos-usecase) + frontend (payment-frontend)"
  kubectl create namespace dtusecase 2>/dev/null || true
  kubectl apply -f "$FRAMEWORK_APPS_PATH/dtpay/manifests/dtpay.yaml"
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
# Usage: runJmeterTest [version]
#   version: v1.0 (default), v1.2, v1.3, v1.4, v2.0
runJmeterTest() {
  local version="${1:-v1.0}"
  local valid_versions="v1.0 v1.2 v1.3 v1.4 v2.0"

  if ! echo "$valid_versions" | grep -qw "$version"; then
    printWarn "Unknown version '$version'. Valid options: $valid_versions"
    return 1
  fi

  printInfoSection "Running JMeter load test against dtpay (image: domuharahap/jmeter-tester:$version)"

  local target_url
  target_url=$(getAppURL "payment-frontend" 2>/dev/null || echo "payment-frontend.127.0.0.1.sslip.io")
  # Strip any protocol prefix — JMeter manifest expects a bare hostname
  target_url="${target_url#http://}"
  target_url="${target_url#https://}"

  printInfo "JMeter target URL: $target_url"

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

  kubectl apply -n jmeter -f "$FRAMEWORK_APPS_PATH/jmeter-tester/manifests/jmeter-job.yaml"

  # Patch image version and target URL at runtime
  kubectl set image job/jmeter-tester -n jmeter jmeter-tester="domuharahap/jmeter-tester:$version"
  kubectl set env job/jmeter-tester -n jmeter JVM_APP_URL="$target_url"

  printInfo "JMeter job submitted (version $version). Waiting for completion (up to 15 min)..."
  kubectl wait --for=condition=complete job/jmeter-tester -n jmeter --timeout=900s \
    && printInfo "JMeter test completed successfully." \
    || printWarn "JMeter job timed out or failed — check: kubectl logs -n jmeter -l app=jmeter-tester"
  printInfo "The job namespace will be auto-cleaned 60s after completion."
}

stopJmeterTest() {
  printInfoSection "Stopping JMeter test"
  kubectl delete job jmeter-tester -n jmeter 2>/dev/null || true
  kubectl delete ns jmeter --force 2>/dev/null || true
}





