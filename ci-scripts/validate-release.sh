#!/usr/bin/env sh

set -x


for D in ./profiles/* ; do if [ -d "${D}" ]; then dirr="${D}" ; git log -n 1 --pretty=format:%H -- $dirr | cut -c 1-8 ; fi ; done
SERVER_PROFILE_SHA=something

# install the new profiles, but don't move on until install is successfully deployed. 
helm upgrade --install \
  sg-dev-fs pingidentity/devops \
  --set pingfederate-admin.envs.SERVER_PROFILE_SHA=abc123 \
  -f helm/dev-values.yaml \
  --wait --timeout 10m0s

kubectl run microservices-tests -i --rm \
  --restart=Never --image=samirgandhi/integration-tests \
  -- run /etc/tests/refci-tests.postman_collection.json --insecure --ignore-redirects