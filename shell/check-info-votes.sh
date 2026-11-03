#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> check-info-votes.sh"
set -u unset

ref=$(echo "$GERRIT_REFSPEC" | awk -F"/" '{ print $4 }')

# shellcheck disable=SC1090
source ~/lf-env.sh
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

echo "Checking votes:"
LEGACY_CLI=1 lftools-uv infofile check-votes INFO.yaml "$GERRIT_URL" \
    "$ref" > gerrit_comment.txt
exit_status="$?"

if [[ "$exit_status" -ne 0 ]]; then
    echo "Vote not yet complete"
    cat gerrit_comment.txt
    exit "$exit_status"
else
    echo "Vote completed submitting review"
    ssh -p "$GERRIT_PORT" "$USER"@"$GERRIT_HOST" gerrit review \
        "$GERRIT_PATCHSET_REVISION" --verified 1
    sleep 5
    ssh -p "$GERRIT_PORT" "$USER"@"$GERRIT_HOST" gerrit review \
        "$GERRIT_PATCHSET_REVISION" --submit
fi
