#!/bin/bash
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

#provided by jenkins
LOGS_SERVER=${LOGS_SERVER}
NEXUS_URL=${NEXUS_URL}
ODLNEXUSPROXY=${ODLNEXUSPROXY}
JENKINS_HOSTNAME=${JENKINS_HOSTNAME}
SILO=${SILO}

LOGS_SERVER="${LOGS_SERVER:-None}"
if [ "${LOGS_SERVER}" == 'None' ]; then
  echo "FAILED: log server not found"
  exit 1
else
  NEXUS_URL="${ODLNEXUSPROXY:-$NEXUS_URL}"
  NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/"
fi

RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")

#need pip install jsonschema for this.
echo "--> Verifying $RELEASE_FILES Schema."
for release_file in $RELEASE_FILES; do
  #not schema file not yet written
  echo "lftools schema verify [OPTIONS] $release_file $SCHEMAFILE"
done

for release_file in $RELEASE_FILES; do

  VERSION="$(niet ".version" "$release_file")"
  PROJECT="$(niet ".project" "$VERSION".yaml)"
  LOG_DIR="$(niet ".log_dir" "$VERSION".yaml)"
  MAVEN_CENTRAL_URL="$(niet ".maven_central_url" "$VERSION.yaml")"
  LOGS_URL="$LOGS_SERVER"/"$NEXUS_PATH"/"$LOG_DIR"
  PATCH_DIR=/tmp/patches

  mkdir -p $PATCH_DIR
  cd $PATCH_DIR
  rm -f "${PROJECT}".bundle taglist.log{,.gz} staging-repo.txt.gz
  wget --quiet "${LOGS_URL}"staging-repo.txt.gz
  STAGING_REPO="$(zcat staging-repo.txt)"


  if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "Running merge"
    if ! [ -z "$NEXUS_URL" ]; then
      lftools nexus release --server "$NEXUS_URL" "$STAGING_REPO"
    fi

    if ! [ -z "$MAVEN_CENTRAL_URL" ]; then
      lftools nexus release --server "$MAVEN_CENTRAL_URL" "$STAGING_REPO"
    fi

    wget --quiet  "${LOGS_URL}"/patches/{"${PROJECT}".bundle,taglist.log.gz}
    gunzip taglist.log.gz
    cd -
    git checkout "$(awk '{print $NF}' "$PATCH_DIR/taglist.log")"
    git fetch "$PATCH_DIR/$PROJECT.bundle"
    git merge --ff-only FETCH_HEAD
    git tag -asm "$PROJECT $VERSION" "v$VERSION"
    git push origin "v$VERSION"

  else
    echo "Verification Complete"
  fi

done
