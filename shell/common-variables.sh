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

    error_detected=0
    mapfile -t files < <(find "$stage_dir" -name maven-metadata.xml | grep SNAPSHOT)

    for f in "${files[@]}"; do
        timestamp=$(xmlstarlet sel \
            -t -v "/metadata/versioning/snapshot/timestamp" "$f")

        # Scan all snapshot versions but ignore javadoc and source jars
        mapfile -t ext_timestamps < <(xmlstarlet sel \
            -t -m "/metadata/versioning/snapshotVersions/snapshotVersion" \
            -n \
            --if "classifier='javadoc'" \
               -o "" \
            --elif "classifier='sources'" \
               -o "" \
            --else \
               -o "extension:" -v extension \
               -o " value:" -v value \
               -o " updated:" -v updated \
            "$f")

        for t in "${ext_timestamps[@]}"; do
            # Ignore blank timestamps caused by xmlstarlet ignores
            if [[ -z "$t" ]]; then
                continue
            fi

            timestamp_error=0
            if [[ $t != *"$timestamp"* ]]; then
                echo "Metadata $f 'value:$timestamp' mismatch vs '$t'"
                timestamp_error=1
            fi
            # Updated is timestamp without the dot character
            if [[ $t != *"${timestamp//\./}"* ]]; then
                echo "Metadata $f 'updated:${timestamp//\./}' mismatch vs '$t'"
                timestamp_error=1
            fi

            if [[ $timestamp_error != 0 ]]; then
                error_detected=1
                cat "$f"
            fi
        done
    done

    if [ $error_detected -ne 0 ]; then
        echo "ERROR: Mismatches in maven-metadata discovered. Quitting..."
        exit 1
    fi
}
