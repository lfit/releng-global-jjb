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
echo "---> release-job.sh"
set -eu -o pipefail

#Python bits. Remove when centos 7.7 builder is avaliable.
if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
PYTHONPATH=$(pwd)
export PYTHONPATH
pyenv local 3.6.4
export PYENV_VERSION="3.6.4"
pip install --user lftools[nexus] jsonschema niet yq

#Functions.
verify_schema(){
  echo "---> INFO: Verifying $release_file schema."
  lftools schema verify "$release_file" "$RELEASE_SCHEMA"
  # Verify allowed versions
  # Allowed versions are "v#.#.#" or "#.#.#" aka SemVer
  allowed_version_regex="^((v?)([0-9]+)\.([0-9]+)\.([0-9]+))$"
  if [[ ! $VERSION =~ $allowed_version_regex ]]; then
    echo "The version $VERSION is not a semantic valid version"
    echo "Allowed versions are \"v#.#.#\" or \"#.#.#\" aka SemVer"
    echo "See https://semver.org/ for more details on SemVer"
    exit 1
  fi
}

tag(){
  if git tag -v "$VERSION"; then
    echo "---> OK: Repo already tagged $VERSION Continuting to release"
  else

    echo "---> INFO: Repo has not yet been tagged $VERSION"
    git tag -am "${PROJECT//\//-} $VERSION" "$VERSION"
    sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" "$VERSION" < "$SIGUL_PASSWORD"
    echo "Showing latest signature for $PROJECT:"
    gpg --import "$SIGNING_PUBKEY"
    echo "git tag -v $VERSION"
    git tag -v "$VERSION"
    ########## Merge Part ##############
    if [[ "$JOB_NAME" =~ "merge" ]]; then
      echo "--> INFO: Running merge"
      gerrit_ssh=$(echo "$GERRIT_URL" | awk -F"/" '{print $3}')
      git remote set-url origin ssh://"$RELEASE_USERNAME"@"$gerrit_ssh":29418/"$PROJECT"
      git config user.name "$RELEASE_USERNAME"
      git config user.email "$RELEASE_EMAIL"
      echo -e "Host $gerrit_ssh\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
      chmod 600 ~/.ssh/config
      git push origin "$VERSION"
    fi
  fi
}

nexus_release(){
  for staging_url in $(zcat "$PATCH_DIR"/staging-repo.txt.gz | awk -e '{print $2}'); do
    # extract the domain name from URL
    NEXUS_URL=$(echo "$staging_url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    echo "---> INFO: NEXUS_URL: $NEXUS_URL"
    # extract the staging repo from URL
    STAGING_REPO=${staging_url#*repositories/}
    echo "Running Nexus Verify"
    lftools nexus release -v --server https://"$NEXUS_URL" "$STAGING_REPO"
    echo "Merge will run"
    echo "lftools nexus release --server https://$NEXUS_URL $STAGING_REPO"
    if [[ "$JOB_NAME" =~ "merge" ]]; then
      echo "Promoting $STAGING_REPO on $NEXUS_URL."
      lftools nexus release --server https://"$NEXUS_URL" "$STAGING_REPO"
    fi
  done
}

container_release_file(){
  echo "---> Processing container release"
  # Container-release code is addressed in a new feature patchset.
}

maven_release_file(){
  echo "---> INFO: wget -P $PATCH_DIR ${LOGS_URL}/staging-repo.txt.gz"
  wget -P "$PATCH_DIR" "${LOGS_URL}/"staging-repo.txt.gz
  pushd "$PATCH_DIR"
    echo "---> INFO: wget ${LOGS_URL}/patches/{${PROJECT//\//-}.bundle,taglist.log.gz}"
    wget "${LOGS_URL}"/patches/{"${PROJECT//\//-}".bundle,taglist.log.gz}
    gunzip taglist.log.gz
    cat "$PATCH_DIR"/taglist.log
  popd
  git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
  git fetch "$PATCH_DIR/${PROJECT//\//-}.bundle"
  git merge --ff-only FETCH_HEAD
  nexus_release
  tag
}

echo "########### Start Script release-job.sh ###################################"
echo "---> INFO: Setting all VARS"

LOGS_SERVER="${LOGS_SERVER:-None}"
MAVEN_CENTRAL_URL="${MAVEN_CENTRAL_URL:-None}"
if [ "${LOGS_SERVER}" == 'None' ]; then
    echo "FAILED: log server not found"
    exit 1
fi

RELEASE_FILE="${RELEASE_FILE:-True}"
if [[ "$RELEASE_FILE" == "True" ]]; then

  release_files=$(git diff-tree --no-commit-id -r "$GERRIT_PATCHSET_REVISION" --name-only -- "releases/" ".releases/")
  if (( $(grep -c . <<<"$release_files") > 1 )); then
    echo "---> INFO: RELEASE FILES ARE AS FOLLOWS: $release_files"
    echo "---> ERROR: Committing multiple release files in the same commit OR rename/amend of existing files is not supported."
    exit 1
  else
    release_file="$release_files"
    echo "---> INFO: RELEASE FILE: $release_files"
  fi

else
  echo "This is job is built with parameters, no release file needed"
  release_file="None"
fi


NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"

VERSION="${VERSION:-None}"
if [[ $VERSION == "None" ]]; then
  VERSION="$(niet ".version" "$release_file")"
fi

LOG_DIR="${LOG_DIR:-None}"
if [[ $LOG_DIR == "None" ]]; then
  LOG_DIR="$(niet ".log_dir" "$release_file")"
fi

DISTRIBUTION_TYPE="${DISTRIBUTION_TYPE:-None}"
if [[ $DISTRIBUTION_TYPE == "None" ]]; then
  DISTRIBUTION_TYPE="$(niet ".distribution_type" "$release_file")"
fi

####
LOGS_URL="${LOGS_SERVER}/${NEXUS_PATH}${LOG_DIR}"
LOGS_URL=${LOGS_URL%/}  # strip any trailing '/'
PATCH_DIR="$(mktemp -d)"
#INFO
echo "INFO:"
echo "RELEASE_FILE: $release_file"
echo "LOGS_SERVER: $LOGS_SERVER"
echo "NEXUS_PATH: $NEXUS_PATH"
echo "JENKINS_HOSTNAME: $JENKINS_HOSTNAME"
echo "SILO: $SILO"
echo "PROJECT: $PROJECT"
echo "PROJECT-DASHED: ${PROJECT//\//-}"
echo "VERSION: $VERSION"
echo "LOG DIR: $LOG_DIR"
echo "LOGS URL: $LOGS_URL"
echo "DISTRIBUTION_TYPE: $DISTRIBUTION_TYPE"
#Check if this is a container or maven release: release-container-schema.yaml vs release-schema.yaml

#Logic to determine what we are releasing.
##########################################
if [[ "$DISTRIBUTION_TYPE" == "maven" ]]; then
  wget -q https://raw.githubusercontent.com/lfit/releng-global-jjb/master/schema/release-schema.yaml
  RELEASE_SCHEMA="release-schema.yaml"
  if [[ "$RELEASE_FILE" == "True" ]]; then
    verify_schema
  fi
  maven_release_file
elif [[ "$DISTRIBUTION_TYPE" == "container" ]]; then
  # Container-release code is addressed in a new feature patchset.
  container_release_file
else
  echo "---> ERROR: distribution_type: $DISTRIBUTION_TYPE not supported"
  echo "Must be maven or container"
  exit 1
fi
##########################################

echo "########### End Script release-job.sh ###################################"

