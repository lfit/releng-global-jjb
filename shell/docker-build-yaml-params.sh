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

set -eu -o pipefail

cd "$DOCKER_ROOT"

# WIP - Will fetch the parameters from YAML
image_build_tag=''
image_name="$CONTAINER_PULL_REGISTRY/$DOCKER_NAME:$image_build_tag"
image_name_latest="$CONTAINER_PULL_REGISTRY/$DOCKER_NAME:latest"

docker build "$DOCKER_ARGS" . -t "$image_name" -t "$image_name_latest" | tee "$WORKSPACE/docker_build_log.txt"

# Write DOCKER_IMAGE information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE=$image_name" >> "$WORKSPACE/env_docker_inject.txt"
echo "DOCKER_IMAGE_LATEST=$image_name_latest" >> "$WORKSPACE/env_docker_inject.txt"
