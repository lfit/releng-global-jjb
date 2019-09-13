#!/bin/bash
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

set -eu -o pipefail -o noglob

if [[ -z ${LOGS_SERVER:-} ]]; then
    echo "WARNING: Logging server not set: Nothing to do"
else
    nexus_url="${NEXUSPROXY:-$NEXUS_URL}"
    nexus_path="$SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER"

    # Convert multiple search extensions to list of arguments'
    # "ext1 ext2" -> "-p ext1 -p ext2"
    pattern_opts=""
    for i in ${ARCHIVE_ARTIFACTS:-}; do
        pattern_opts+="-p $i "
    done

    # Use lftools from user pyenv
    lftools=~/.local/bin/lftools
    $lftools deploy archives $pattern_opts $nexus_url $nexus_path $WORKSPACE
    $lftools deploy logs $nexus_url $nexus_path $BUILD_URL

    echo "Build logs: <a href='$LOGS_SERVER/$nexus_path' > $LOGS_SERVER/$nexus_path</a>"
fi
