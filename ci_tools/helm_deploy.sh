#!/usr/bin/env sh

set -x
# set -e

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

# REMOVE ALL THIS ONCE VARIABLES ARE DEFINED BY DEVOPS TEAM
export RELEASE
envsubst < "${VALUES_FILE}" > "${VALUES_FILE}.final"
VALUES_FILE="${VALUES_FILE}.final"

# # install the new profiles, but don't move on until install is successfully deployed. 
# # tied to chart version to avoid breaking changes.
helm upgrade --install \
  "${RELEASE}" pingidentity/ping-devops \
  --set pingdirectory.envs.PD_PROFILE_SHA="${pingdirectorySha}" \
  --set pingfederate-admin.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set pingfederate-admin.envs.PF_ADMIN_PROFILE_SHA="${pingfederate_adminSha}" \
  --set pingfederate-engine.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set global.envs.SERVER_PROFILE_BRANCH="${REF}" \
  --set pingfederate-admin.envs.SERVER_PROFILE_BASE_BRANCH="${REF}" \
  -f "${VALUES_FILE}" \
  --namespace "${K8S_NAMESPACE}" --version "${CHART_VERSION}" \
  --force --atomic --timeout "${_timeout}"

test "${?}" -ne 0 && exit 1

helm history "${RELEASE}"
