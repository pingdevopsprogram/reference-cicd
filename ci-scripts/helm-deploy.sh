#!/usr/bin/env sh

set -x -e

_ref=$(git rev-parse --abbrev-ref HEAD)
PING_ENV=${PING_ENV:=sg-dev-fs}
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

for _prodName in  pingdirectory pingfederate_admin pingfederate; do
  echo "$_prodName Sha is:" "$(eval "echo \${${_prodName}Sha}")"
  case ${_prodName} in
    pingdirectory)
      timeout="10m0s"
      _helmVars="--set pingdirectory.envs.PD_PROFILE_SHA=${pingdirectorySha}"
      ;;
    pingfederate_admin)
      _helmVars="--set pingfederate-admin.envs.PF_ADMIN_PROFILE_SHA=${pingfederate_adminSha} --set pingfederate-admin.envs.PF_PROFILE_SHA=${pingfederateSha}"
      timeout="1m30s"
      ;;
    pingfederate)
      _helmVars="--set pingfederate-engine.envs.PF_PROFILE_SHA=${pingfederateSha}"
      timeout="2m0s"
      ;;
    *)
      timeout="2m0s"
      ;;
  esac

  helm upgrade --install \
    "${PING_ENV}" pingidentity/ping-devops \
    ${_helmVars} \
    --set global.envs.SERVER_PROFILE_BRANCH="${_ref}" \
    -f helm/dev-values.yaml \
    --force --atomic --timeout "${timeout}"
done


test "${?}" -ne 0 && exit 1

helm history "${PING_ENV}"
