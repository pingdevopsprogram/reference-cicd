#!/usr/bin/env sh

test -z "${REF}" && REF=$(git rev-parse --abbrev-ref HEAD)

case "${REF}" in
  qa )
    RELEASE=${RELEASE:=qa} 
    K8S_NAMESPACE=${K8S_NAMESPACE:=sg-qa} 
    ;;
  master ) 
    RELEASE=${RELEASE:=qa}
    K8S_NAMESPACE=${K8S_NAMESPACE:=sg-prod} 
    ;;
  * )
    RELEASE="${REF}"
    K8S_NAMESPACE=${K8S_NAMESPACE:=sg-dev} 
    ;;
esac

VALUES_FILE=${VALUES_FILE:=helm/values.yaml}
CHART_VERSION="0.3.8"
CURRENT_SHA=$(git log -n 1 --pretty=format:%h)

getGlobalVars() {
  kubectl get cm "${RELEASE}-global-env-vars" -o=jsonpath='{.data}' -n "${K8S_NAMESPACE}" | jq -r '. | to_entries | .[] | .key + "=" + .value + ""'
}

getPfVars() {
export PF_ADMIN_PUBLIC_HOSTNAME=$(kubectl get ing -l app.kubernetes.io/instance=${RELEASE},app.kubernetes.io/name=pingfederate-admin -o=jsonpath='{.items[0].spec.rules[0].host}')
PING_IDENTITY_PASSWORD="2FederateM0re"
}

