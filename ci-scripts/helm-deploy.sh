#!/usr/bin/env sh

set -x

_ref=$(git rev-parse --abbrev-ref HEAD)
echo _ref

## builds sha for each product based on the folder name in ./profiles/* (e.g. pingfederateSha)
for D in ./profiles/* ; do 
  if [ -d "${D}" ]; then 
    _prodName=$(basename "${D}")
    dirr="${D}"
    eval "${_prodName}Sha=$(git log -n 1 --pretty=format:%h -- "$dirr")"
  fi
done

# # install the new profiles, but don't move on until install is successfully deployed. 
# # tied to chart version to avoid breaking changes.
##TODO - turn this into a loop, 1 deploy for each product, so it's easier to rollback failures.  
helm upgrade --install \
  "${_pingEnv}" pingidentity/ping-devops \
  --set pingfederate-admin.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
  --set pingfederate-engine.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
  --set pingdirectory.envs.SERVER_PROFILE_SHA="${pingdirectorySha}" \
  --set global.envs.SERVER_PROFILE_BRANCH="${_ref}" \
  -f helm/dev-values.yaml \
  --atomic --timeout 10m0s

helm history "${_pingEnv}"
