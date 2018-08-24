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

set -x  # Trace commands for this script to make debugging easier.

ARCHIVE_ARTIFACTS="${ARCHIVE_ARTIFACTS:-}"
LOGS_SERVER="${LOGS_SERVER:-None}"

if [ "${LOGS_SERVER}" == 'None' ]
then
    set +x # Disable trace since we no longer need it

    echo "WARNING: Logging server not set"
else
    NEXUS_URL="${NEXUSPROXY:-$NEXUS_URL}"
    NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/${JOB_NAME}/${BUILD_NUMBER}"
    BUILD_URL="${BUILD_URL}"

    lftools deploy archives -p "$ARCHIVE_ARTIFACTS" "$NEXUS_URL" "$NEXUS_PATH" "$WORKSPACE"
    lftools deploy logs "$NEXUS_URL" "$NEXUS_PATH" "$BUILD_URL"

    set +x  # Disable trace since we no longer need it.

    echo "Build logs: <a href=\"$LOGS_SERVER/$NEXUS_PATH\">$LOGS_SERVER/$NEXUS_PATH</a>"
fi
