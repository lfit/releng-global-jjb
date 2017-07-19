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

# This script publishes packages (rpms/debs) or any file to Nexus hosted
# maven2 repository.
#
# $NEXUS_URL          :  Jenkins global variable should be defined.
# $REPO_ID            :  Provided by a job parameter.
# $GROUP_ID           :  Provided by a job parameter.
# $UPLOAD_FILES_PATH  :  Provided by a job parameter.
echo "---> deploy-maven-file.sh"
# Ensure we fail the job if any steps fail.
set -eu -o pipefail

DEPLOY_LOG="$WORKSPACE/archives/deploy-maven-file.log"
mkdir -p "$WORKSPACE/archives"

NEXUS_REPO_URL="${NEXUS_URL}/content/repositories/$REPO_ID"

while IFS="" read -r file
do
    lftools deploy maven-file "$NEXUS_REPO_URL" \
                              "$REPO_ID" \
                              "$file" \
                              -b "$MVN" \
                              -g "$GROUP_ID" 2>&1 > "$DEPLOY_LOG"
done < <(find "$UPLOAD_FILES_PATH" -type f -name "*")
