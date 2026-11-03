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
echo "---> maven-stage.sh"
# This script publishes artifacts to a staging repo in Nexus.
#
# $WORKSPACE/m2repo   :  Exists and used to deploy the staging repository.
# $NEXUS_URL          :  Jenkins global variable should be defined.
# $STAGING_PROFILE_ID :  Provided by a job parameter.

# Ensure we fail the job if any steps fail.
set -xeu -o pipefail

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

TMP_FILE="$(mktemp)"
lftools-uv deploy nexus-stage "$NEXUS_URL" "$STAGING_PROFILE_ID" "$WORKSPACE/m2repo" | tee "$TMP_FILE"
staging_repo=$(sed -n -e 's/Staging repository \(.*\) created\./\1/p' "$TMP_FILE")

# Store repo info to a file in archives
mkdir -p "$WORKSPACE/archives"
echo "$staging_repo ${NEXUS_URL}/content/repositories/$staging_repo" | tee -a "$WORKSPACE/archives/staging-repo.txt"

# Cleanup
rm -f "$TMP_FILE"
