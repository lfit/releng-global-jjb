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
echo "---> maven-central.sh"

profile_id="${OSSRH_PROFILE_ID:-}"

# Ensure we fail the job if any steps fail.
set -eux -o pipefail

# shellcheck disable=SC1090
. ~/lf-env.sh
# An agent's ~/lf-env.sh is copied when it boots, so may predate lftools-uv.
if ! declare -F lftools-uv > /dev/null; then
    lf_env="$(mktemp)"
    lf_env_url="https://raw.githubusercontent.com/lfit/releng-global-jjb"
    wget -nv -O "$lf_env" "$lf_env_url/${GLOBAL_JJB_VERSION:-master}/jenkins-init-scripts/lf-env.sh" || true
    # shellcheck disable=SC1090
    source "$lf_env"
    rm -f "$lf_env"
    if ! declare -F lftools-uv > /dev/null; then
        echo "ERROR: lf-env.sh has no lftools-uv function" >&2
        exit 1
    fi
fi

MC_TMP_FILE="$(mktemp)"
echo "Staging in OSSRH for Maven Central"
lftools-uv deploy nexus-stage "https://oss.sonatype.org" "$profile_id" "$WORKSPACE/m2repo" | tee "$MC_TMP_FILE"
mc_staging_repo=$(sed -n -e 's/Staging repository \(.*\) created\./\1/p' "$MC_TMP_FILE")
rm -f "$MC_TMP_FILE"

# shellcheck disable=SC2140
echo "$mc_staging_repo "\
"https://oss.sonatype.org/content/repositories/$mc_staging_repo" | \
    tee -a "$WORKSPACE/archives/staging-repo.txt"
