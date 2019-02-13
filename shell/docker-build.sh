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

cd "$DOCKER_ROOT"
docker build "$DOCKER_ARGS" . -t "$DOCKER_IMAGE" | tee "$WORKSPACE/docker_build_log.txt"
