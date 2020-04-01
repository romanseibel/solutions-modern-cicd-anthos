#!/bin/bash -x

if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi
if [ -z ${GITLAB_TOKEN} ];then
  read -p "What is the GitLab token? " GITLAB_TOKEN
fi

rm -rf anthos-config-management
git clone https://root:${GITLAB_TOKEN}@${GITLAB_HOSTNAME}/platform-admins/anthos-config-management.git
cd anthos-config-management

HIPSTER_NAMESPACE=namespaces/managed-apps/hipster-shop
PETABANK_NAMESPACE=namespaces/managed-apps/petabank
FRONTEND_NAMESPACE=namespaces/managed-apps/hipster-frontend

pushd ${HIPSTER_NAMESPACE}
  HS_ALLOW_EXTERNAL_FRONTEND=$(grep -e "name: allow-external-hipster-frontend" network-policy.yaml)
  if [ -z "${HS_ALLOW_EXTERNAL_FRONTEND}" ]; then
    rm network-policy.yaml
    cp ../../../templates/hipster-shop/network-policy.yaml ./
  else
    echo "Network Policy already allows Hipster Shop's Frontend traffic"
  fi
popd

pushd ${PETABANK_NAMESPACE}
  PB_ALLOW_EXTERNAL_FRONTEND=$(grep -e "name: allow-external-hipster-frontend" network-policy.yaml)
  if [ -z "${PB_ALLOW_EXTERNAL_FRONTEND}" ]; then
    rm network-policy.yaml
    cp ../../../templates/petabank/network-policy.yaml ./
  else
    echo "Network Policy already allows Hipster Shop's Frontend traffic"
  fi
popd

pushd ${FRONTEND_NAMESPACE}
  FE_ALLOW_EXTERNAL_WEB=$(grep -e "name: allow-external-web" network-policy.yaml)
  if [ -z "${FE_ALLOW_EXTERNAL_WEB}" ]; then
    rm network-policy.yaml
    cp ../../../templates/hipster-frontend/network-policy.yaml ./
  else
    echo "Network Policy already allows external web traffic"
  fi
popd

if [ -z "${HS_ALLOW_EXTERNAL_FRONTEND}" ] || [ -z "${PB_ALLOW_EXTERNAL_FRONTEND}" ] || [ -z "${FE_ALLOW_EXTERNAL_WEB}" ]; then
  git add .
  git commit -m "Setup Network Policies for Hipster Shop and Petabank"
  git push -u origin master
else
  echo "No configuration changes needeed."
fi
