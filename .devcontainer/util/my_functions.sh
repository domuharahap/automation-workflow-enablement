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
  kubectl create namespace dtpay 2>/dev/null || true
  kubectl -n dtpay apply -f "$FRAMEWORK_APPS_PATH/dtpay/manifests/dtpay.yaml"
  waitForAllReadyPods dtpay
  registerApp "payment-frontend" "dtpay" "payment-frontend" 80
  printInfo "dtpay deployed. Frontend URL: $(getAppURL payment-frontend)"
}

undeployDtpay() {
  printInfoSection "Undeploying dtpay"
  unregisterApp "payment-frontend" "dtpay"
  kubectl delete ns dtpay --force 2>/dev/null || true
}

# Deploy EdgeConnect — fetches DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ENVIRONMENT, DT_URN_ACCOUNT
# from the environment and substitutes them into the manifest before applying.
# No credentials are written to disk; substitution happens in-memory via sed.
deployEdgeConnect() {
  [ -z "$FRAMEWORK_APPS_PATH" ] && { echo "❌ source_framework.sh not loaded — run 'source .devcontainer/util/source_framework.sh' first"; return 1; }

  printInfoSection "Deploying EdgeConnect (k8s-workshop) into namespace dynatrace"

  local missing=()
  [[ -z "${DT_CLIENT_ID:-}" ]]     && missing+=("DT_CLIENT_ID")
  [[ -z "${DT_CLIENT_SECRET:-}" ]] && missing+=("DT_CLIENT_SECRET")
  [[ -z "${DT_ENVIRONMENT:-}" ]]   && missing+=("DT_ENVIRONMENT")
  [[ -z "${DT_URN_ACCOUNT:-}" ]]   && missing+=("DT_URN_ACCOUNT")

  if [[ ${#missing[@]} -gt 0 ]]; then
    printError "Missing required environment variables: ${missing[*]}"
    printError "Set them as Codespace secrets or export them before calling deployEdgeConnect."
    return 1
  fi

  # apiServer expects hostname only — strip any https:// or http:// prefix
  local dt_api_server="${DT_ENVIRONMENT#https://}"
  dt_api_server="${dt_api_server#http://}"

  printInfo "Substituting credentials and applying EdgeConnect manifest..."
  sed \
    -e "s|DT_CLIENT_ID|${DT_CLIENT_ID}|g" \
    -e "s|DT_CLIENT_SECRET|${DT_CLIENT_SECRET}|g" \
    -e "s|DT_ENVIRONMENT|${dt_api_server}|g" \
    -e "s|DT_URN_ACCOUNT|${DT_URN_ACCOUNT}|g" \
    "${FRAMEWORK_APPS_PATH}/edgeconnect/edgeconnect.yaml" | kubectl apply -f -

  printInfo "Verifying EdgeConnect resources..."
  kubectl get edgeconnect -n dynatrace
  kubectl get pods -n dynatrace | grep edgeconnect || printWarn "EdgeConnect pod not yet visible — check again in ~60s with: kubectl get pods -n dynatrace"
  printInfo "EdgeConnect deployed. It will register as 'k8s-workshop' in Dynatrace > Infrastructure > Kubernetes > EdgeConnect"
}

undeployEdgeConnect() {
  [ -z "$FRAMEWORK_APPS_PATH" ] && { echo "❌ source_framework.sh not loaded — run 'source .devcontainer/util/source_framework.sh' first"; return 1; }

  printInfoSection "Undeploying EdgeConnect (k8s-workshop) from namespace dynatrace"
  kubectl delete -f "${FRAMEWORK_APPS_PATH}/edgeconnect/edgeconnect.yaml" 2>/dev/null || true
  printInfo "EdgeConnect resources removed from dynatrace namespace."
}







