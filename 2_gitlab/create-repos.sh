#!/bin/bash -xe
if [ -z ${GITLAB_HOSTNAME} ];then
  read -p "What is the GitLab hostname (i.e. my.gitlab.server)? " GITLAB_HOSTNAME
fi

if [ -z ${GITLAB_TOKEN} ];then
read -p "What is the access token? " GITLAB_TOKEN
fi

REPOS="anthos-config-management shared-kustomize-bases shared-ci-cd golang-template golang-template-env kustomize-docker kaniko-docker"

pushd gitlab-repos
  # Create deloy keys so we can push the source code
  mkdir -p ../ssh-keys
  pushd ../ssh-keys
    for repo in ${REPOS}; do
       ssh-keygen -f ${repo} -N ''
    done
  popd
  terraform init
  terraform plan -var gitlab_token=${GITLAB_TOKEN} -var gitlab_hostname=${GITLAB_HOSTNAME}
  terraform apply -var gitlab_token=${GITLAB_TOKEN} -var gitlab_hostname=${GITLAB_HOSTNAME}
popd

pushd repos
  for repo in ${REPOS}; do
    pushd ${repo}
      export GIT_SSH_COMMAND="ssh -i ../../ssh-keys/${repo}"
      rm -rf .git
      git init
      if [ "${repo}" == "golang-template" ];then
        sed -i s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g k8s/stg/kustomization.yaml
        sed -i s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g k8s/prod/kustomization.yaml
        sed -i s/GITLAB_HOSTNAME/${GITLAB_HOSTNAME}/g k8s/dev/kustomization.yaml
      fi
      git add .
      git commit -m "Initial commit"
      git remote add origin git@${GITLAB_HOSTNAME}:platform-admins/${repo}.git
      git push origin master
    popd
  done
popd