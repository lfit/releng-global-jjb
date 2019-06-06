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
echo "---> docker-get-yaml-tag.sh"
# Gets the container tag from a yaml file.

set -eu -o pipefail

cd "$DOCKER_ROOT"

# Verify if the CONTAINER_TAG_FILE_PATH variable ends with "/"
# Add "/" if not.
if [[ "$CONTAINER_TAG_FILE_PATH" = */ ]]
then
    container_tag_file="$CONTAINER_TAG_FILE_PATH"container-tag.yaml
else
    container_tag_file="$CONTAINER_TAG_FILE_PATH"/container-tag.yaml
fi
echo "---> Looking for tag in $container_tag_file ..."

if [ -f "$container_tag_file" ]
then
    image_build_tag=$(yq -r .tag "$container_tag_file")
else
    echo "$container_tag_file file not found. Make sure this file exists."
    exit 1
fi
echo "---> Tag found: $image_build_tag"
# Write DOCKER_IMAGE_TAG information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE_TAG=$image_build_tag" >> "$WORKSPACE/env_docker_inject.txt"
