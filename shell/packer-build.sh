#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> packer-build.sh"
# The script builds an image using packer
#
# $PACKER_PLATFORM     :  Provided by a job parameter.
# $PACKER_TEMPLATE     :  Provided by a job parameter.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

mkdir -p "$WORKSPACE/archives"
PACKER_BUILD_LOG="$WORKSPACE/archives/packer-build.log"

cd packer
export PACKER_LOG="yes" && \
export PACKER_LOG_PATH="$PACKER_BUILD_LOG" && \
                 packer.io build -color=false \
                        -var-file="$CLOUDENV" \
                        -var-file="../packer/vars/$PACKER_PLATFORM.json" \
                        "../packer/templates/$PACKER_TEMPLATE.json"

# Split public and private cloud logs
grep -e 'public_cloud' "$PACKER_BUILD_LOG" > "$WORKSPACE/archives/packer-build_public_cloud.log"  2>&1
grep -e 'private_cloud' "$PACKER_BUILD_LOG" > "$WORKSPACE/archives/packer-build_private_cloud.log" 2>&1
