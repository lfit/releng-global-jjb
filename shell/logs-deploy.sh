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

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

if [[ -v LOGS_SERVER ]]; then
    nexus_url="${NEXUSPROXY:-$NEXUS_URL}"
    nexus_path="$SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER"

    pattern_opts=""
    for arg in ${ARCHIVE_ARTIFACTS:-}; do
        pattern_opts+="-p $arg "
    done

    lftools deploy archives $pattern_opts "$nexus_url" "$nexus_path" "$WORKSPACE"
    lftools deploy logs "$nexus_url" "$nexus_path" "${BUILD_URL:-}"

    echo "Build logs: <a href=\"$LOGS_SERVER/$nexus_path\">$LOGS_SERVER/$nexus_path</a>"
else
    echo "WARNING: Logging server not setup"
fi
