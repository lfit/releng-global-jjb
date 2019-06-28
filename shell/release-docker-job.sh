#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
set -eu -o pipefail
echo "---> release-docker-job.sh"

if [ -d "/opt/pyenv" ]; then
  echo "---> Setting up pyenv"
  export PYENV_ROOT="/opt/pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
PYTHONPATH=$(pwd)
export PYTHONPATH
pyenv local 3.6.4
export PYENV_VERSION="3.6.4"

pip install --user lftools[nexus] jsonschema niet

echo "########### Start Script release-docker-job.sh ###################################"

logs_server="${logs_server:-None}"
dockerhub_url="${dockerhub_url:-None}"

if [ "${logs_server}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
fi

nexus3_url="${ODLNEXUSPROXY:-$nexus3_url}"

release_files=$(git diff HEAD^1 --name-only -- "releases-docker/")
echo "RELEASE FILES ARE AS FOLLOWS: $release_files"

for release_file in $release_files; do
  echo "This is the release file: $release_file"
  echo "--> Verifying $release_file Schema."
  #OPTIONAL
  if grep -q "\.dockerhub_url" "$release_file"; then
    dockerhub_url="$(niet ".dockerhub_url" "$release_file")"
  fi
  echo "DUMMY CODE:"
  #Make sure the schema check catches a missing trailing / on log_dir
  #lftools schema is written, but not the schema file (yet)
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"

  DOCKER_NAME="$(niet ".docker_name" "$release_file")"
  DOCKER_IMAGE_TAG="$(niet ".docker_image_tag" "$release_file")"
  PROJECT="$(niet ".project" "$release_file")"
  LOG_DIR="$(niet ".log_dir" "$release_file")"

  NEXUS3_PATH="${SILO}/${JENKINS_HOSTNAME}/"
  LOGS_URL="${logs_server}/${NEXUS_PATH}${LOG_DIR}"
  PATCH_DIR="$(mktemp -d)"

  pushd "$PATCH_DIR"
    wget --quiet "${LOGS_URL}"staging-repo.txt.gz
    STAGING_REPO="$(zcat staging-repo.txt)"

    #INFO
    echo "INFO:"
    echo "RELEASE_FILE: $release_file"
    echo "LOGS_SERVER: $logs_server"
    echo "NEXUS3_URL: $nexus3_url"
    echo "NEXUS3_PATH: $NEXUS3_PATH"
    echo "ODLNEXUSPROXY: $ODLNEXUSPROXY"
    echo "JENKINS_HOSTNAME: $JENKINS_HOSTNAME"
    echo "SILO: $SILO"
    echo "PROJECT: $PROJECT"
    echo "STAGING_REPO: $STAGING_REPO"
    echo "DOCKER_IMAGE_TAG: $DOCKER_IMAGE_TAG"
    echo "DOCKER_NAME: $DOCKER_NAME"
    echo "PROJECT: $PROJECT"
    echo "LOG DIR: $LOG_DIR"

    wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
    gunzip taglist.log.gz
    cat "$PATCH_DIR"/taglist.log
  popd

  git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
  git fetch "$PATCH_DIR/$PROJECT.bundle"
  git merge --ff-only FETCH_HEAD
  git tag -am "$PROJECT $DOCKER_IMAGE_TAG" "$DOCKER_IMAGE_TAG"
  sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" v"$DOCKER_IMAGE_TAG" < "$SIGUL_PASSWORD"
  echo "Showing latest signature for $PROJECT:"
  git log --show-signature -n1

  ########## Merge Part ##############
  if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "Running merge"
    git push origin "$DOCKER_IMAGE_TAG"
    docker pull $CONTAINER_PULL_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG
    docker_image_id=$(docker images | grep $DOCKER_NAME | awk '{print $3}')
    docker tag $docker_image_id $CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG
    docker push $CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG
    lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
    if [ "${dockerhub_url}" == 'None' ]; then
      echo "No DockerHub url specified, not pushing to DockerHub"
    else
      docker tag $docker_image_id $dockerhub_url/$DOCKER_NAME:$DOCKER_IMAGE_TAG
      docker push $dockerhub_url/$DOCKER_NAME:$DOCKER_IMAGE_TAG
    fi
  fi

done
echo "########### End Script release-docker-job.sh ###################################"
