#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
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
# $CLOUDENV            :  Provides the cloud credential file.
# $PACKER_PLATFORM     :  Provides the packer platform.
# $PACKER_TEMPLATE     :  Provides the packer temnplate.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

PACKER_LOGS_DIR="$WORKSPACE/archives/packer"
PACKER_BUILD_LOG="$PACKER_LOGS_DIR/packer-build.log"
mkdir -p "$PACKER_LOGS_DIR"
export PATH="${WORKSPACE}/bin:$PATH"

cd packer

# Prioritize the project's own version of vars if available
platform_file="common-packer/vars/$PACKER_PLATFORM.json"
if [[ -f "vars/$PACKER_PLATFORM.json" ]]; then
    platform_file="vars/$PACKER_PLATFORM.json"
fi

export PACKER_LOG="yes"
export PACKER_LOG_PATH="$PACKER_BUILD_LOG"
packer.io validate \
    -var-file="$CLOUDENV" \
    -var-file="$platform_file" \
    "templates/$PACKER_TEMPLATE.json"
packer.io build -color=false \
    -var-file="$CLOUDENV" \
    -var-file="$platform_file" \
    "templates/$PACKER_TEMPLATE.json"

# Extract image name from log and store value in the downstream job
if [[ ${UPDATE_CLOUD_IMAGE} ]]; then

    NEW_IMAGE_NAME=$(grep -P '(\s+.*image: )(ZZCI\s+.*\d+-\d+\.\d+)' \
                          "$PACKER_BUILD_LOG" | awk -F': ' '{print $4}')

    echo NEW_IMAGE_NAME="$NEW_IMAGE_NAME" >> "$WORKSPACE/variables.prop"
    echo "NEW_IMAGE_NAME: ${NEW_IMAGE_NAME}"

    # Copy variables.prop to variables.jenkins-trigger so that the end of build
    # trigger can pick up the file as input for triggering downstream jobs.
    # Dont tigger downstream job when UPDATE_CLOUD_IMAGE is set to 'false'
    cp "$WORKSPACE/variables.prop" "$WORKSPACE/variables.jenkins-trigger"
fi

# Retrive the list of cloud providers
mapfile -t clouds < <(jq -r '.builders[].name' "templates/$PACKER_TEMPLATE.json")

# Split public/private clouds logs
for cloud in "${clouds[@]}"; do
    grep -e "$cloud" "$PACKER_BUILD_LOG" > "$PACKER_LOGS_DIR/packer-build_$cloud.log" 2>&1
done
