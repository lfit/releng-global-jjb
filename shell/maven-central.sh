#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

profile_id="${OSSRH_PROFILE_ID:-}"

# Ensure we fail the job if any steps fail.
set -eux -o pipefail

MC_TMP_FILE="$(mktemp)"
echo "Staging in OSSRH for Maven Central"
lftools deploy nexus-stage "https://oss.sonatype.org" "$profile_id" "$WORKSPACE/m2repo" | tee "$MC_TMP_FILE"
mc_staging_repo=$(sed -n -e 's/Staging repository \(.*\) created\./\1/p' "$MC_TMP_FILE")
rm -f "$MC_TMP_FILE"

echo "$mc_staging_repo https://oss.sonatype.org/content/repositories/$mc_staging_repo" | tee -a "$WORKSPACE/archives/staging-repo.txt"
