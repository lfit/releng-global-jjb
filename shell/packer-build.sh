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
# $PACKER_BUILDER      :  Provides the packer cloud type.
# $PACKER_PLATFORM     :  Provides the packer platform.
# $PACKER_TEMPLATE     :  Provides the packer template.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

# Functions to compare semantic versions x.y.z
version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

PACKER_LOGS_DIR="$WORKSPACE/archives/packer"
PACKER_BUILD_LOG="$PACKER_LOGS_DIR/packer-build.log"
mkdir -p "$PACKER_LOGS_DIR"
export PATH="${WORKSPACE}/bin:$PATH"
template_file="${template_file:-}"

cd packer

# Pick the correct format (hcl or json) based on packer version
# Prioritize the project's own version of vars if available
if version_ge "$PACKER_VERSION" "1.9.0"; then
    platform_file="common-packer/vars/$PACKER_PLATFORM.pkrvars.hcl"
    template_file="templates/$PACKER_TEMPLATE.pkr.hcl"
    only="${PACKER_BUILDER}.${PACKER_TEMPLATE}"

    if [[ -f "vars/$PACKER_PLATFORM.pkrvars.hcl" ]]; then
        platform_file="vars/$PACKER_PLATFORM.pkrvars.hcl"
    fi
else
    platform_file="common-packer/vars/$PACKER_PLATFORM.json"
    template_file="templates/$PACKER_TEMPLATE.json"
    only="${PACKER_BUILDER}"

    if [[ -f "vars/$PACKER_PLATFORM.json" ]]; then
        platform_file="vars/$PACKER_PLATFORM.json"
    fi
fi

export PACKER_LOG="yes"
export PACKER_LOG_PATH="$PACKER_BUILD_LOG"

# download plugins only for HCL format
if [[ "${template_file#*.}" == "pkr.hcl" ]]; then
    echo "packer init ${template_file} ..."
    packer.io init "${template_file}"
fi

packer.io validate \
    -var-file="$CLOUDENV" \
    -var-file="$platform_file" \
    "$template_file"

set -x
# If this is a Gerrit system, check patch comments for successful verify build.
if [[ -n ${GERRIT_URL:-} ]] && \
   [[ -n ${GERRIT_CHANGE_NUMBER:-} ]] && \
   [[ -n ${GERRIT_PATCHSET_NUMBER:-} ]] && \
   curl -s "${GERRIT_URL}/changes/${GERRIT_CHANGE_NUMBER}/detail" \
   | tail -n +2 | jq .messages[].message? \
   | grep "Patch Set ${GERRIT_PATCHSET_NUMBER}:.*Build Successful.*verify-build-${PACKER_PLATFORM}-${PACKER_TEMPLATE}"
then
    echo "Build already successful for this patch set. Skipping merge build..."
    exit
# If this is Github, check the last non-merge commit for a successful Packer
# Verify Build status.
elif [[ "${GIT_BASE:-}" =~ https://github.com ]]; then
    LAST_CHANGE_SHA=$(git log --no-merges -1 --format=%H)
    API_BASE=$(echo "$GIT_BASE" | sed -E 's#(www.)?github.com#api.github.com/repos#')
    CONTEXT_VALUE="\"Packer ${PACKER_PLATFORM}-${PACKER_TEMPLATE} Verify Build\""
    JQ_QUERY=".[] | select(.state == \"success\" and .context == ${CONTEXT_VALUE})"
    STATUS=$(curl "${API_BASE}/statuses/${LAST_CHANGE_SHA}" | jq "${JQ_QUERY}")
    if [[ -n ${STATUS} ]]; then
        echo "Build already successful for this patch set. Skipping merge build..."
        exit
    fi
fi
set +x

packer.io build -color=false \
    -only "$only" \
    -var-file="$CLOUDENV" \
    -var-file="$platform_file" \
    "$template_file"

# Extract image name from log and store value in the downstream job
if [[ ${UPDATE_CLOUD_IMAGE} == 'true' ]]; then

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
