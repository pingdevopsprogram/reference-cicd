#!/usr/bin/env sh

set -x

## builds sha for each product based on the folder name in ./profiles/* (e.g. pingfederateSha)
for D in ./profiles/* ; do 
  if [ -d "${D}" ]; then 
    _prodName=$(basename "${D}")
    dirr="${D}"
    eval echo "${_prodName}Sha"
    git rev-list -n 1 --no-merges --all  -- "$dirr"
    eval "${_prodName}Sha=$(git rev-list -n 1 --no-merges --all  -- "$dirr" | cut -c 1-8)"
  fi
done

# # install the new profiles, but don't move on until install is successfully deployed. 
# # tied to chart version to avoid breaking changes.
# helm upgrade --install \
#   sg-dev-fs pingidentity/ping-devops \
#   --set pingfederate-admin.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
#   --set pingfederate-engine.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
#   --set pingdirectory.envs.SERVER_PROFILE_SHA="${pingdirectorySha}" \
#   --set global.envs.SERVER_PROFILE_BRANCH="$(echo ${GITHUB_REF} | cut -b 12-)" \
#   -f helm/dev-values.yaml \
#   --wait --timeout 10m0s
