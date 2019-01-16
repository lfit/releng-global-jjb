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
set +x


echo "#######################################"

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

echo $PATH

#provided by jenkins
LOGS_SERVER=${LOGS_SERVER}
NEXUS_URL=${NEXUS_URL}
ODLNEXUSPROXY=${ODLNEXUSPROXY}
JENKINS_HOSTNAME=${JENKINS_HOSTNAME}
SILO=${SILO}


####
#
#set -x  # Trace commands for this script to make debugging easier.
#
#ARCHIVE_ARTIFACTS="${ARCHIVE_ARTIFACTS:-}"
#LOGS_SERVER="${LOGS_SERVER:-None}"
#
#if [ "${LOGS_SERVER}" == 'None' ]
#then
#    set +x # Disable trace since we no longer need it
#
#    echo "WARNING: Logging server not set"
#else
#    NEXUS_URL="${NEXUSPROXY:-$NEXUS_URL}"
#    NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/${JOB_NAME}/${BUILD_NUMBER}"
#    BUILD_URL="${BUILD_URL}"
#
#    lftools deploy archives -p "$ARCHIVE_ARTIFACTS" "$NEXUS_URL" "$NEXUS_PATH" "$WORKSPACE"
#    lftools deploy logs "$NEXUS_URL" "$NEXUS_PATH" "$BUILD_URL"
#
#    set +x  # Disable trace since we no longer need it.
#
#    echo "Build logs: <a href=\"$LOGS_SERVER/$NEXUS_PATH\">$LOGS_SERVER/$NEXUS_PATH</a>"
#fi
#
#
####

LOGS_SERVER="${LOGS_SERVER:-None}"
if [ "${LOGS_SERVER}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
else
  NEXUS_URL="${ODLNEXUSPROXY:-$NEXUS_URL}"
  NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
fi

RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")
echo "RELEASE FILES?: $RELEASE_FILES"
RELEASE_FILES="releases/1.0.0.yaml"

#INFO
#We don't have nexus path
echo "INFO:"
echo "rf $RELEASE_FILES"
echo "ls $LOGS_SERVER"
echo "nu $NEXUS_URL"
echo "odlp $ODLNEXUSPROXY"
echo "jh $JENKINS_HOSTNAME"
echo "s $SILO"
echo "p $PROJECT"

#need pip install jsonschema for this.
echo "--> Verifying $RELEASE_FILES Schema."
for release_file in $RELEASE_FILES; do
  #not schema file not yet written
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"
done

for release_file in $RELEASE_FILES; do
  echo "This is the release file: $release_file"

  VERSION="$(niet ".version" "$release_file")"
  PROJECT="$(niet ".project" "$release_file")"
  LOG_DIR="$(niet ".log_dir" "$release_file")"
# MAVEN_CENTRAL_URL="$(niet ".maven_central_url" "$release_file")"


  LOGS_URL="$LOGS_SERVER"/"$NEXUS_PATH"/"$LOG_DIR"
  #NEXUS PATH SEEMS TO BE NOTHING.. and not needed.
  echo "$LOGS_URL"

  #Hard code for testing..
  LOGS_URL="https://logs.opendaylight.org/releng/vex-yul-odl-jenkins-1/zzz-test-release-maven-stage-master/17/"
  PATCH_DIR=/tmp/patches

  mkdir -p $PATCH_DIR
  cd $PATCH_DIR
  rm -f "${PROJECT}".bundle taglist.log{,.gz} staging-repo.txt.gz
  #mine doesnt have .gz 
# wget https://logs.opendaylight.org/releng/vex-yul-odl-jenkins-1/zzz-test-release-maven-stage-master/17/staging-repo.txt
  wget --quiet "${LOGS_URL}"staging-repo.txt
  #STAGING_REPO="$(zcat staging-repo.txt)"
  STAGING_REPO="$(cat staging-repo.txt)"

  echo $STAGING_REPO

#  if [[ "$JOB_NAME" =~ "merge" ]]; then
#    echo "Running merge"
#    if ! [ -z "$NEXUS_URL" ]; then
      lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
#    fi

#    if ! [ -z "$MAVEN_CENTRAL_URL" ]; then
#      lftools nexus release --server "$MAVEN_CENTRAL_URL" "$STAGING_REPO"
#    fi


#16:30:42 /tmp/jenkins4256085658751084108.sh: line 104: lftools: command not found
#16:30:42 gzip: taglist.log.gz: No such file or directory

    #wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
    wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log}
    #gunzip taglist.log.gz
    cd -
    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/$PROJECT.bundle"
    git merge --ff-only FETCH_HEAD
    git tag -asm "$PROJECT $VERSION" "v$VERSION"
  echo "NOT DOING THIS PART  git push origin "v$VERSION""

  #else
  #  echo "Verification Complete"
#  fi

#this doesnt work if its  merge job
#  cd -

done
