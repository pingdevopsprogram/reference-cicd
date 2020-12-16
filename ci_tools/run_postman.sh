#!/usr/bin/env sh
set -x
collectionId=08a31b94a3b9fd831861
test -n "${1}" && collectionId=${1}
set -a 
# shellcheck source=./ci_tools.lib.sh
. ./ci_tools/ci_tools.lib.sh
set +a

kubectl delete pod integration-tests --force --grace-period=0 --ignore-not-found -n "${K8S_NAMESPACE}"

kubectl get cm "${RELEASE}-global-env-vars" -o=jsonpath='{.data}' -n "${K8S_NAMESPACE}" | jq -r '. | to_entries | .[] | .key + "=" + .value + ""' > env_vars
postman_vars=$(while read line; do echo "--env-var $line "; done < env_vars)

set -x 
kubectl run integration-tests \
-i --rm --restart=Never \
--image=postman/newman \
-- run https://www.getpostman.com/collections/${collectionId} --insecure --ignore-redirects ${postman_vars}