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

echo "---> docker-get-container-tag.sh"

# Gets the container tag per $CONTAINER_TAG_METHOD
# For YAML file use directory $CONTAINER_TAG_YAML_DIR
# if a value is provided, else fall back to $DOCKER_ROOT
# use login flag to get $HOME/.local/bin in PATH

set -feu -o pipefail

tag=""
if [[ $CONTAINER_TAG_METHOD == "latest" ]]; then
    tag="latest"
elif [[ $CONTAINER_TAG_METHOD == "stream" ]]; then
    if [[ $STREAM == "master" ]]; then
	tag="latest"
    else
        tag="$STREAM"
    fi
elif [[ $CONTAINER_TAG_METHOD == "git-describe" ]]; then
    tag=$(git describe)
elif [[ $CONTAINER_TAG_METHOD == "yaml-file" ]]; then
    dir=${CONTAINER_TAG_YAML_DIR:-$DOCKER_ROOT}
    tag_file=$dir/container-tag.yaml
    if [[ -f $tag_file ]]; then
        # pip installs yq to $HOME/.local/bin
        tag=$(yq -r .tag "$tag_file")
    else
        echo "File $tag_file not found."
    fi
else
    echo "Method $CONTAINER_TAG_METHOD not implemented (yet)"
fi
if [[ -z $tag ]]; then
    echo "Failed to get a container tag using method $CONTAINER_TAG_METHOD"
    exit 1
fi
echo "---> Docker image tag found: $tag"
# Write DOCKER_IMAGE_TAG information to a file so it can be
# injected into the environment for following steps
echo "DOCKER_IMAGE_TAG=$tag" >> "$WORKSPACE/env_docker_inject.txt"
