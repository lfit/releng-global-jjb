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

function get_pattern_opts()
{
    opts=()
    for arg in ${ARCHIVE_ARTIFACTS:-}; do
        opts+=("-p" "$arg)")
    done
    echo "${opts[@]-}"
}

pattern_opts="$(get_pattern_opts)"

if [[ -z ${LOGS_SERVER:-} ]]; then
    echo "WARNING: Nexus logging server not set"
else
    nexus_url="${NEXUSPROXY:-$NEXUS_URL}"
    nexus_path="${SILO}/${JENKINS_HOSTNAME}/${JOB_NAME}/${BUILD_NUMBER}"
    echo "INFO: Nexus URL $nexus_url path $nexus_path"

    echo "INFO: archiving workspace using pattern(s): $ARCHIVE_ARTIFACTS"
    lftools deploy archives ${pattern_opts:+"$pattern_opts"} "$nexus_url" "$nexus_path" "$WORKSPACE"

    echo "INFO: archiving logs"
    lftools deploy logs "$nexus_url" "$nexus_path" "${BUILD_URL:-}"

    echo "Build logs: <a href=\"$LOGS_SERVER/$nexus_path\">$LOGS_SERVER/$nexus_path</a>"
fi

if [[ -z ${S3_BUCKET:-} ]]; then
    echo "WARNING: S3 logging server not set"
else
    s3_path="$SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER/"
    echo "INFO: S3 path $s3_path"

    lftools deploy s3 ${pattern_opts:+"$pattern_opts"} "$S3_BUCKET" "$s3_path" \
        "$BUILD_URL" "$WORKSPACE"

    echo "Build logs: <a href=\"https://$S3_BUCKET.s3.amazonaws.com/$s3_path\"></a>"
fi

