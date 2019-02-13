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

set -e -o pipefail

cd "$DOCKER_ROOT"

# DOCKERREGISTRY is purposely not using an '_' so as to not conflict with the
# Jenkins global env var of the DOCKER_REGISTRY which the docker-login step uses
IMAGE_NAME="$DOCKERREGISTRY/$DOCKER_NAME:$DOCKER_TAG"
IMAGE_NAME_LATEST="$DOCKERREGISTRY/$DOCKER_NAME:$DOCKER_LATEST_TAG"

docker build "$DOCKER_ARGS" . -t "$IMAGE_NAME" -t "$IMAGE_NAME_LATEST" | tee "$WORKSPACE/docker_build_log.txt"

# Write DOCKER_IMAGE information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE=$IMAGE_NAME" >> "$WORKSPACE/env_inject.txt"
echo "DOCKER_IMAGE_LATEST=$IMAGE_NAME_LATEST" >> "$WORKSPACE/env_inject.txt"


