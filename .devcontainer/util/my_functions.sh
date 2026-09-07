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







