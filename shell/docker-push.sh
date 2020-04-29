#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> docker-push.sh"
# Docker image push script

# Ensure we fail the job if any steps fail
set -ue -o pipefail
docker --version
echo "Pushing image: $CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG"
docker_push_command="docker push "$CONTAINER_PUSH_REGISTRY/$DOCKER_NAME:$DOCKER_IMAGE_TAG""
echo "$docker_push_command"
eval "$docker_push_command"
echo "---> docker-push.sh ends"
