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
echo "---> logs-deploy.sh"

# Ensure we fail the job if any steps fail
# Disable 'globbing'
set -euf -o pipefail

if [[ -z $"${LOGS_SERVER:-}" ]]; then
    echo "WARNING: Logging server not set"
else
    nexus_url="${NEXUSPROXY:-$NEXUS_URL}"
    nexus_path="${SILO}/${JENKINS_HOSTNAME}/${JOB_NAME}/${BUILD_NUMBER}"

    if [[ -n ${ARCHIVE_ARTIFACTS:-} ]] ; then
        # Handle multiple search extensions as separate values to '-p|--pattern'
        # "arg1 arg2" -> (-p arg1 -p arg2)
        pattern_opts=()
        for arg in $ARCHIVE_ARTIFACTS; do
            pattern_opts+=("-p" "$arg")
        done
        lftools deploy archives "${pattern_opts[@]}" \
                "$nexus_url" "$nexus_path" "$WORKSPACE"
    else
        lftools deploy archives "$nexus_url" "$nexus_path" "$WORKSPACE"
    fi
    lftools deploy logs "$nexus_url" "$nexus_path" "${BUILD_URL:-}"

    echo "Build logs: <a href=\"$LOGS_SERVER/$nexus_path\">$LOGS_SERVER/$nexus_path</a>"
fi
