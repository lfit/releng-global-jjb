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

# This file contains a list of variables that are generally useful in many
# scripts. It is meant to be sourced in other scripts so that the variables can
# be called.

MAVEN_OPTIONS="$(echo --show-version \
    --batch-mode \
    -Djenkins \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
    -Dmaven.repo.local=/tmp/r \
    -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r)"
echo "$MAVEN_OPTIONS"

# Activates the lftools virtualenv
lftools_activate() {
    virtualenv --quiet "/tmp/v/lftools"
    set +u  # Ignore unbound variables in activate
    # shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
    source "/tmp/v/lftools/bin/activate"
    set -u  # Restore unbound variable checking
}

# Check maven-metadata.xml for any unexpected timestamp mismatches
maven_metadata_validate() {
    stage_dir="$1"

    if [ -z "$1" ]; then
        echo "Usage: maven_metadata_validate STAGE_REPO_DIR"
        exit 1
    fi

    error=0
    mapfile -t files < <(find "$stage_dir" -name maven-metadata.xml | grep SNAPSHOT)

    for f in "${files[@]}"; do
        timestamp=$(xmlstarlet sel -t -v "/metadata/versioning/snapshot/timestamp" "$f")
        mapfile -t ext_timestamps < <(xmlstarlet sel -t -m "/metadata/versioning/snapshotVersions/snapshotVersion" -v extension -v "' '" -v value -v "' '" -v updated -n "$f")

        for t in "${ext_timestamps[@]}"; do
            if [[ $t != *"$timestamp"* ]]; then
                echo "Snapshot 'value' mismatch in $t vs $timestamp"
                error=1
            fi

            # Updated is timestamp without the dot character
            if [[ $t != *"${timestamp//\./}"* ]]; then
                echo "Snapshot 'updated' mismatch in ${t//\./} vs ${timestamp//\./}"
                error=1
            fi
        done
    done

    if [ $error -ne 0 ]; then
        echo "ERROR: Mismatches in maven-metadata discovered. Quitting..."
        exit 1
    fi
}
