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
echo "---> cmake-stage.sh"

classifier="${CLASSIFIER:-linux-amd64}"
nexus_group_id="${NEXUS_GROUP_ID:-io.aswf.opencolorio}"
staging_profile_id="${STAGING_PROFILE_ID:-126694cb53ec54}"
version="${VERSION:-}"

# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"

set -eux -o pipefail

if [ -z "${nexus_group_id}" ]; then
    echo "ERROR: No nexus group ID provided."
    exit 1
fi

if [ -z "${staging_profile_id}" ]; then
    echo "ERROR: No staging profile ID provided."
    exit 1
fi

if [ -z "${version}" ]; then
    if [ -f "/tmp/artifact_version" ]; then
        version="$(cat /tmp/artifact_version)"
    else
        echo "ERROR: No artifact version defined."
        exit 1
    fi
fi

repo_id=$(lftools deploy nexus-stage-repo-create "$NEXUS_URL" "$staging_profile_id")

mapfile -t artifacts < <(ls "$WORKSPACE"/dist)
for artifact in "${artifacts[@]}"; do
    lftools deploy file -c "$classifier" "$NEXUS_URL" "$repo_id" \
        "$nexus_group_id" \
        "${artifact%.tar.xz}" \
        "$version" \
        tar.xz \
        "$WORKSPACE/dist/$artifact"

    # Create src tar
    git config tar.tar.xz.command "xz -c"
    git archive --format=tar.xz HEAD > src.tar.xz
    lftools deploy file -c "sources" "$NEXUS_URL" "$repo_id" \
        "$nexus_group_id" \
        "${artifact%.tar.xz}" \
        "$version" \
        tar.xz \
        src.tar.xz
done

lftools deploy nexus-stage-repo-close "$NEXUS_URL" "$staging_profile_id" "$repo_id"

PATCH_DIR="$WORKSPACE/archives/patches"
mkdir -p "$PATCH_DIR"
echo "$PROJECT" "$(git rev-parse --verify HEAD)" | tee -a "$PATCH_DIR/taglist.log"
echo "$repo_id" > "$WORKSPACE/archives/staging-repo.txt"
