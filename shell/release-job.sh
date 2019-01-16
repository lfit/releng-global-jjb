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
#set -e -o pipefail
#set +x

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

echo "#######################################"
echo "$PATH"

#provided by jenkins
NEXUS_URL=${NEXUS_URL}
ODLNEXUSPROXY=${ODLNEXUSPROXY}
JENKINS_HOSTNAME=${JENKINS_HOSTNAME}
SILO=${SILO}
LOGS_SERVER="${LOGS_SERVER:-None}"
#
if [ "${LOGS_SERVER}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
else
  NEXUS_URL="${ODLNEXUSPROXY:-$NEXUS_URL}"
  NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
fi

RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")
echo "RELEASE FILES ARE AS FOLLOWS: $RELEASE_FILES"

#need pip install jsonschema for this.
echo "--> Verifying $RELEASE_FILES Schema."
for release_file in $RELEASE_FILES; do
  #not schema file not yet written
  echo "DUMMY CODE:"
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"
done

for release_file in $RELEASE_FILES; do
  echo "This is the release file: $release_file"

  VERSION="$(niet ".version" "$release_file")"
  PROJECT="$(niet ".project" "$release_file")"
  LOG_DIR="$(niet ".log_dir" "$release_file")"

  echo "version: $VERSION"
  echo "project: $PROJECT"
  echo "log dir: $LOG_DIR"


# need some sort of if here incase its unset
# MAVEN_CENTRAL_URL="$(niet ".maven_central_url" "$release_file")"

  #Hard code for testing..
  #ON SANDBOX
  #NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
  #NEXUS_PATH=sandbox/vex-yul-odl-jenkins-2/
  #WE NEED NEXUS_PATH=releng/vex-yul-odl-jenkins-1/
  NEXUS_PATH=releng/vex-yul-odl-jenkins-1/
  LOGS_URL="$LOGS_SERVER"/"$NEXUS_PATH""$LOG_DIR"
  PATCH_DIR=/tmp/patches

  mkdir -p "$PATCH_DIR"
  cd "$PATCH_DIR" || exit

  rm -f "${PROJECT}".bundle taglist.log{,.gz} staging-repo.txt.gz

  #Do we need a check for cases where things are not gzipped?
  #mine dont have .gz
  #hmm we need to check for cases of a missing / on log_dir
  wget --quiet "${LOGS_URL}"staging-repo.txt
  #STAGING_REPO="$(zcat staging-repo.txt)"
  STAGING_REPO="$(cat staging-repo.txt)"

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

#  if [[ "$JOB_NAME" =~ "merge" ]]; then
#    echo "Running merge"
#    if ! [ -z "$NEXUS_URL" ]; then

  echo "lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO""
#    fi

#    if ! [ -z "$MAVEN_CENTRAL_URL" ]; then
#      lftools nexus release --server "$MAVEN_CENTRAL_URL" "$STAGING_REPO"
#    fi


    wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log}
    #gunzip taglist.log.gz
    cat $PATCH_DIR/taglist.log
    cd -
    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/$PROJECT.bundle"
    git merge --ff-only FETCH_HEAD

    git tag -am "$PROJECT $VERSION" "v$VERSION"
    #how do I get KEYNAME?
    printf "${SIGUL_PASSWORD}\0" | /bin/sigul --batch sign-git-tag "$KEYNAME" "v$VERSION"

    git tag -l
    which sigul
    sigul --help
    echo "NOT DOING THIS PART  git push origin "v$VERSION""

  #else
  #  echo "Verification Complete"
#  fi

#this doesnt work if its  merge job
#  cd -

done
