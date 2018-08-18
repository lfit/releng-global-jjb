#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This script publishes artifacts to a staging repo in Nexus.
#
# $WORKSPACE/m2repo   :  Exists and used to deploy the staging repository.
# $NEXUS_URL          :  Jenkins global variable should be defined.
# $STAGING_PROFILE_ID :  Provided by a job parameter.

mvn_central="${MVN_CENTRAL:-false}"

# Ensure we fail the job if any steps fail.
set -xeu -o pipefail

TMP_FILE="$(mktemp)"
lftools deploy nexus-stage "$NEXUS_URL" "$STAGING_PROFILE_ID" "$WORKSPACE/m2repo" | tee "$TMP_FILE"
staging_repo=$(sed -n -e 's/Staging repository \(.*\) created\./\1/p' "$TMP_FILE")
rm -f "$TMP_FILE"

# Store repo info to a file in archives
mkdir -p "$WORKSPACE/archives"
echo "$staging_repo ${NEXUS_URL}/content/repositories/$staging_repo" > "$WORKSPACE/archives/staging-repo.txt"

if [ "$mvn_central" == true ]; then
    MC_TMP_FILE="$(mktemp)"
    echo "Staging in OSSRH for Maven Central"
    lftools deploy nexus-stage "https://oss.sonatype.org" "7edbe315063867" "$WORKSPACE/m2repo" | tee "$MC_TMP_FILE"
    mc_staging_repo=$(sed -n -e 's/Staging repository \(.*\) created\./\1/p' "$MC_TMP_FILE")
    rm -f "$MC_TMP_FILE"

    echo "$mc_staging_repo https://oss.sonatype.org/content/repositories/$mc_staging_repo" >> "$WORKSPACE/archives/staging-repo.txt"
fi
