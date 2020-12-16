#!/usr/bin/env sh

REF=$(git rev-parse --abbrev-ref HEAD)
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
CHART_VERSION="0.3.7"
CURRENT_SHA=$(git log -n 1 --pretty=format:%h)