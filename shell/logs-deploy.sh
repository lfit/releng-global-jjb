#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

set -x  # Trace commands for this script to make debugging easier.

LOGS_SERVER="${LOGS_SERVER:-WARNING: Logging Server Not Set.}"
NEXUS_URL="${NEXUS_URL:-$NEXUSPROXY}"
NEXUS_PATH="${SILO}/${JENKINS_HOSTNAME}/${JOB_NAME}/${BUILD_NUMBER}"
BUILD_URL="${BUILD_URL}"

lftools deploy archives "$NEXUS_URL" "$NEXUS_PATH" "$WORKSPACE"
lftools deploy logs "$NEXUS_URL" "$NEXUS_PATH" "$BUILD_URL"

set +x  # Disable trace since we no longer need it.

echo "Build logs: <a href=\"$LOGS_SERVER/$NEXUS_PATH\">$LOGS_SERVER/$NEXUS_PATH</a>"
