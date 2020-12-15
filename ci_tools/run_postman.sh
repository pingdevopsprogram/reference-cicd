#!/usr/bin/env sh
set -a 
. ../helm/tmp-env
set +a

kubectl delete pod integration-tests --force --grace-period=0 --ignore-not-found -n "${K8S_NAMESPACE}"

kubectl get cm global-samir-tmp-env-vars -o=jsonpath='{.data}' -n "${K8S_NAMESPACE}" | jq -r '. | to_entries | .[] | .key + "=" + .value + ""' > env_vars
postman_vars=$(while read line; do echo "--env-var $line "; done < env_vars)

set -x 
kubectl run integration-tests \
-i --rm --restart=Never \
--image=postman/newman \
-- run https://www.getpostman.com/collections/ee0397d76d78f82a7aa8 --insecure --ignore-redirects ${postman_vars}