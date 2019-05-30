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
echo "---> docker-get-git-describe.sh"
# Gets the container tag using git describe.

set -eu -o pipefail

cd "$DOCKER_ROOT"

image_build_tag=$(git describe)

if [ -z "$image_build_tag" ]
then
    echo "git describe returned an empty value, make sure a version tag is applied"
    exit 1
else
    image_name="$DOCKER_NAME:$image_build_tag"
fi

# Write DOCKER_IMAGE information to a file so it can be injected into the
# environment for following steps
echo "DOCKER_IMAGE=$image_name" >> "$WORKSPACE/env_docker_inject.txt"
