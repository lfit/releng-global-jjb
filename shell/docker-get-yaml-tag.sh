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
echo "---> docker-get-yaml-tag.sh"
# Gets the container tag from a yaml file.

set -eu -o pipefail

# Install yq to read container-tag.yaml
python -m pip install --user --quiet --upgrade yq
export PATH="/home/jenkins/.local/bin:$PATH"

cd "$DOCKER_ROOT"
container_tag_file=container-tag.yaml

if [ -f "$container_tag_file" ]
then
    image_name=$(yq -r .tag "$container_tag_file")
else
    echo "$container_tag_file file not found. Make sure this file exists."
    exit 1
fi

# Write DOCKER_IMAGE information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE=$image_name" >> "$WORKSPACE/env_docker_inject.txt"
