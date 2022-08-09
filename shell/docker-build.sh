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
echo "---> docker-build.sh"
# Docker image build script

set -eu -o pipefail
docker --version
echo "Building image: $CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG"
cd "$DOCKER_ROOT"
# DOCKER_IMAGE_TAG variable gets constructed after lf-docker-get-container-tag
# builder step is executed. It constructs the image name and the appropriate
# tag in the same varaiable.
docker_build_command="docker build ${DOCKER_ARGS:-} \
    -t "$CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG" ."
echo "$docker_build_command"
eval "$docker_build_command" | tee "$WORKSPACE/docker_build_log.txt"
echo "---> docker-build.sh ends"
