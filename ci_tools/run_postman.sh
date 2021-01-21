#!/usr/bin/env sh

## Usage: ./run_postman.sh iac_file.yaml
## filename must be equal to job name
# set -x
set -a 
# shellcheck source=./ci_tools.lib.sh
. ./ci_tools/ci_tools.lib.sh
set +a

set -x

createGlobalVarsPostman

iacFile="${1}"
test ! -f "${iacFile}" && echo "${iacFile} - file not found" && exit 1
jobName=$(basename "$iacFile")
jobName=${jobName%.yaml}
envsubst < "${iacFile}" > "${iacFile}.final"
iacFileFinal="${iacFile}.final"

kubectl delete -f "${iacFileFinal}" --ignore-not-found --force --grace-period=0 -n "${K8S_NAMESPACE}"

kubectl apply -f "${iacFileFinal}" -n "${K8S_NAMESPACE}"

timeout=30
echo "waiting ${timeout}s for ${jobName} to complete "
while true ; do
  status="$(kubectl get job ${jobName} -o jsonpath='{.status.conditions[0].type}' --ignore-not-found -n ${K8S_NAMESPACE})"
  if test "${status}" = "Complete" -o "${status}" = "Failed" ; then
    break
  fi
  sleep 1
  timeout=$((timeout-1))
  test $timeout -le 1 && echo "JOB TIMED OUT" && break
done

kubectl logs "job/${jobName}" -n "${K8S_NAMESPACE}"

echo "Job Status: ${status}"
kubectl delete -f "${iacFileFinal}" --ignore-not-found -n "${K8S_NAMESPACE}"
test "${status}" = "Complete" && exit 0