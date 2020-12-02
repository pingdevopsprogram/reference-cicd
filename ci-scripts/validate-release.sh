#!/usr/bin/env sh

set -x

## builds sha for each product based on the folder name in ./profiles/* (e.g. pingfederateSha)
for D in ./profiles/* ; do 
  if [ -d "${D}" ]; then 
    _prodName=$(basename "${D}")
    dirr="${D}"
    eval "${_prodName}Sha=$(git log -n 1 --pretty=format:%H -- "$dirr" | cut -c 1-8)"
  fi
done

# install the new profiles, but don't move on until install is successfully deployed. 
# tied to chart version to avoid breaking changes.
helm upgrade --install \
  sg-dev-fs pingidentity/ping-devops \
  --set pingfederate-admin.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
  --set pingfederate-engine.envs.SERVER_PROFILE_SHA="${pingfederateSha}" \
  --set pingdirectory.envs.SERVER_PROFILE_SHA="${pingdirectorySha}" \
  --set global.envs.SERVER_PROFILE_BRANCH="${TRAVIS_BRANCH}" \
  -f helm/dev-values.yaml \
  --wait --timeout 10m0s


## remove old integration test
kubectl delete pod integration-tests
## kickoff integration tests

kubectl run integration-tests -i --rm \
  --restart=Never --image=samirgandhi/integration-tests \
  -- run /etc/tests/refci-tests.postman_collection.json --insecure --ignore-redirects