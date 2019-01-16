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
set -e -o pipefail

if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi
PYTHONPATH=$(pwd)
export PYTHONPATH
pyenv local 3.6.4
export PYENV_VERSION="3.6.4"

pip3 install --user niet
pip3 install --user lftools
pip3 install --user lftools[nexus]
pip3 install --user jsonschema

echo "#######################################"
echo "$PATH"

#Provided by jenkins
NEXUS_URL=${NEXUS_URL}
ODLNEXUSPROXY=${ODLNEXUSPROXY}
JENKINS_HOSTNAME=${JENKINS_HOSTNAME}
SILO=${SILO}
LOGS_SERVER="${LOGS_SERVER:-None}"
MAVEN_CENTRAL_URL="${MAVEN_CENTRAL_URL:-None}"

if [ "${LOGS_SERVER}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
else
  NEXUS_URL="${ODLNEXUSPROXY:-$NEXUS_URL}"
  NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
fi

RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")
echo "RELEASE FILES ARE AS FOLLOWS: $RELEASE_FILES"

for release_file in $RELEASE_FILES; do
  echo "This is the release file: $release_file"
  echo "--> Verifying $RELEASE_FILES Schema."
  echo "DUMMY CODE:"
  #Make sure the schema check catches a missing trailing / on log_dir
  #lftools schema is written, but not the schema file (yet)
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"

  VERSION="$(niet ".version" "$release_file")"
  PROJECT="$(niet ".project" "$release_file")"
  LOG_DIR="$(niet ".log_dir" "$release_file")"

  #OPTIONAL
  if grep "\.maven_central_url" 1.0.0.yaml; then
  MAVEN_CENTRAL_URL="$(niet ".maven_central_url" "$release_file")"
  fi

  #make an if server = sandbox?
  #########################
  #Hard code for testing..
  #ON SANDBOX
  #NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
  #NEXUS_PATH=sandbox/vex-yul-odl-jenkins-2/
  #
  #WE NEED NEXUS_PATH=releng/vex-yul-odl-jenkins-1/
  #########################

  NEXUS_PATH=releng/vex-yul-odl-jenkins-1/
  LOGS_URL="$LOGS_SERVER"/"$NEXUS_PATH""$LOG_DIR"
  PATCH_DIR=/tmp/patches"$release_file"
  OLD_PATH="$(pwd)"

  mkdir -p "$PATCH_DIR"
  cd "$PATCH_DIR" || exit

  #Do we need a check for cases where things are not gzipped?
  #mine dont have .gz
  #https://jenkins.opendaylight.org/releng/job/zzz-test-release-maven-stage-master/
  wget --quiet "${LOGS_URL}"staging-repo.txt
  STAGING_REPO="$(cat staging-repo.txt)"
  #### My job doesnt gzip the logs for some reason..
  #wget --quiet "${LOGS_URL}"staging-repo.txt.gz
  #STAGING_REPO="$(zcat staging-repo.txt)"

  #INFO
  echo "INFO:"
  echo "RELEASE_FILES: $RELEASE_FILES"
  echo "LOGS_SERVER: $LOGS_SERVER"
  echo "NEXUS_URL: $NEXUS_URL"
  echo "NEXUS_PATH: $NEXUS_PATH"
  echo "ODLNEXUSPROXY: $ODLNEXUSPROXY"
  echo "JENKINS_HOSTNAME: $JENKINS_HOSTNAME"
  echo "SILO: $SILO"
  echo "PROJECT: $PROJECT"
  echo "STAGING_REPO: $STAGING_REPO"
  echo "VERSION: $VERSION"
  echo "PROJECT: $PROJECT"
  echo "LOG DIR: $LOG_DIR"

  #normally we would need to fetch gzipped versions
  #wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
  #gunzip taglist.log.gz
  wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log}
  cat "$PATCH_DIR"/taglist.log
  cd "$OLD_PATH" || exit

  git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
  git fetch "$PATCH_DIR/$PROJECT.bundle"
  git merge --ff-only FETCH_HEAD
  git tag -am "$PROJECT $VERSION" "v$VERSION"
  sigul --batch -c "$SIGUL_CONFIG" sign-git-tag "$SIGUL_KEY" v"$VERSION" < "$SIGUL_PASSWORD"
  echo "Showing tags for $PROJECT:"
  git tag -l

  ########## Merge Part ##############
  if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "Running merge"
    git push origin "v$VERSION"
    lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
    if [ "${MAVEN_CENTRAL_URL}" == 'None' ]; then
      echo "No Maven central url specified, not pushing to maven central"
    else
      lftools nexus release --server "$MAVEN_CENTRAL_URL" "$STAGING_REPO"
    fi
  fi

  cd "$OLD_PATH" || exit

done
