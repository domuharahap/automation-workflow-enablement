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

# Deploy dtpay (domuharahap/sampleusecase) — Java Spring Boot demo app on port 8080
deployDtpay() {
  printInfoSection "Deploying dtpay (dtdemo-usecase)"
  kubectl create namespace dtpay 2>/dev/null || true
  kubectl apply -n dtpay -f "$FRAMEWORK_APPS_PATH/dtpay/manifests/dtpay.yaml"
  waitForAllReadyPods dtpay
  registerApp "dtpay" "dtpay" "dtpay" 8080
  printInfo "dtpay deployed. URL: $(getAppURL dtpay)"
}

undeployDtpay() {
  printInfoSection "Undeploying dtpay"
  unregisterApp "dtpay" "dtpay"
  kubectl delete ns dtpay --force 2>/dev/null || true
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
  target_url=$(getAppURL "dtpay" 2>/dev/null || echo "dtpay.127.0.0.1.sslip.io")
  # Strip any protocol prefix — JMeter manifest expects a bare hostname
  target_url="${target_url#http://}"
  target_url="${target_url#https://}"

  printInfo "JMeter target URL: $target_url"

  kubectl create namespace jmeter 2>/dev/null || true

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





