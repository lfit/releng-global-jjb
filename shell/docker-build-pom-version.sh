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

# Docker image build script

set -ue -o pipefail

full_date=`date +'%Y%m%dT%H%M%S'`
image_version=`xmlstarlet sel -N "x=http://maven.apache.org/POM/4.0.0" -t -v "/x:project/x:version" pom.xml | cut -c1-5`

case "$BUILD_MODE" in
   "STAGING")
      DOCKER_TAG="$image_version"-STAGING-"$full_date"Z
      DOCKER_LATEST_TAG="$image_version"-STAGING-latest
      echo "Using tags $DOCKER_TAG and $DOCKER_LATEST_TAG"
      ;;
   "SNAPSHOT")
      DOCKER_TAG="$image_version"-SNAPSHOT-"$full_date"Z
      DOCKER_LATEST_TAG="$image_version"-SNAPSHOT-latest
      echo "Using tags $DOCKER_TAG and $DOCKER_LATEST_TAG"
      ;;
esac

cd "$DOCKER_ROOT"

# DOCKERREGISTRY is purposely not using an '_' so as to not conflict with the
# Jenkins global env var of the DOCKER_REGISTRY which the docker-login step uses
image_name="$DOCKERREGISTRY/$DOCKER_NAME:$DOCKER_TAG"
image_name_latest="$DOCKERREGISTRY/$DOCKER_NAME:$DOCKER_LATEST_TAG"

docker build "$DOCKER_ARGS" . -t "$image_name" -t "$image_name_latest" | tee "$WORKSPACE/docker_build_log.txt"

# Write DOCKER_IMAGE information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE=$image_name" >> "$WORKSPACE/env_inject.txt"
echo "DOCKER_IMAGE_LATEST=$image_name_latest" >> "$WORKSPACE/env_inject.txt"


