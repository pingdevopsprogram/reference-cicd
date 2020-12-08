#!/usr/bin/env sh

set -x -e

_ref=$(git rev-parse --abbrev-ref HEAD)
PING_ENV=${PING_ENV:=sg-dev-fs}
echo ${_ref}
_currentSha=$(git log -n 1 --pretty=format:%h)

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
_timeout="4m0s"
test "${pingdirectorySha}" = "${_currentSha}" && _timeout="10m0s"

# # install the new profiles, but don't move on until install is successfully deployed. 
# # tied to chart version to avoid breaking changes.
helm upgrade --install \
  "${PING_ENV}" pingidentity/ping-devops \
  --set pingdirectory.envs.PD_PROFILE_SHA="${pingdirectorySha}" \
  --set pingfederate-admin.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set pingfederate-admin.envs.PF_ADMIN_PROFILE_SHA="${pingfederate_adminSha}" \
  --set pingfederate-engine.envs.PF_PROFILE_SHA="${pingfederateSha}" \
  --set global.envs.SERVER_PROFILE_BRANCH="${_ref}" \
  --set global.envs.SERVER_PROFILE_ADMIN_BRANCH="${_ref}" \
  -f helm/dev-values.yaml \
  --force --atomic --timeout "${_timeout}"

test "${?}" -ne 0 && exit 1

helm history "${PING_ENV}"
