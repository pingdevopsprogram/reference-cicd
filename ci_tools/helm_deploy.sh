#!/usr/bin/env sh

set -x
# set -e

set -a
# shellcheck source=./ci_tools.lib.sh
. ./ci_tools/ci_tools.lib.sh

## builds sha for each product based on the folder name in ./profiles/* (e.g. pingfederateSha)
  ## this determines what will be redeployed. 
for D in ./profiles/* ; do 
  if [ -d "${D}" ]; then 
    _prodName=$(basename "${D}")
    dirr="${D}"
    eval "${_prodName}Sha=$(git log -n 1 --pretty=format:%h -- "$dirr")"
  fi
done

#try to minimize extended crashloops
_timeout="5m0s"
test "${pingdirectorySha}" = "${CURRENT_SHA}" && _timeout="10m0s"
test ! "$(helm history "${RELEASE}")" && _timeout="15m0s"


export RELEASE
envsubst < "${VALUES_FILE}" > "${VALUES_FILE}.final"
VALUES_FILE="${VALUES_FILE}.final"

# cat $VALUES_FILE

## DELETE ONCE VAULT IS WORKING
## Getting Client ID+Secret for this app.
getPfClientAppInfo


# # install the new profiles, but don't move on until install is successfully deployed. 
# # tied to chart version to avoid breaking changes.
helm upgrade --install \
  "${RELEASE}" pingidentity/ping-devops \
  --set pingdirectory.envs.PD_PROFILE_SHA="${pingdirectorySha}" \
  --set pingfederate-admin.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set pingfederate-admin.envs.PF_ADMIN_PROFILE_SHA="${pingfederate_adminSha}" \
  --set pingfederate-admin.envs.PF_OIDC_CLIENT_ID="${pfEnvClientId}" \
  --set pingfederate-admin.envs.PF_OIDC_CLIENT_SECRET="${pfEnvClientSecret}" \
  --set pingfederate-engine.envs.PF_OIDC_CLIENT_ID="${pfEnvClientId}" \
  --set pingfederate-engine.envs.PF_OIDC_CLIENT_SECRET="${pfEnvClientSecret}" \
  --set pingfederate-engine.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set global.envs.SERVER_PROFILE_BRANCH="${REF}" \
  --set pingfederate-admin.envs.SERVER_PROFILE_BASE_BRANCH="${REF}" \
  -f "${VALUES_FILE}" \
  --namespace "${K8S_NAMESPACE}" --version "${CHART_VERSION}" \
  --atomic --timeout "${_timeout}"

test "${?}" -ne 0 && exit 1

helm history "${RELEASE}"
