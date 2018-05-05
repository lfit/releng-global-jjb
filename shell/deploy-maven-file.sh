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
# $MAVEN_REPO_URL     :  Provided by a job parameter.
#                        The calling job can set $NEXUS_URL path or local
#                        directory to stage files. ex:
#                         -Durl="${NEXUS_URL}/content/repositories/$REPO_ID"
#                         -Durl="file://$WORKSPACE/m2repo"
# $REPO_ID            :  Provided by a job parameter.
#                        A repository ID represents the repository.
# $GROUP_ID           :  Provided by a job parameter.
#                        A group ID represents a nexus group.
# $UPLOAD_FILES_PATH   :  Provided by a job parameter.
#                        The directory contains one or more artifacts.

echo "---> deploy-maven-file.sh"

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

export MAVEN_OPTIONS
export MAVEN_PARAMS

DEPLOY_LOG="$WORKSPACE/archives/deploy-maven-file.log"
mkdir -p "$WORKSPACE/archives"

while IFS="" read -r file
do
    file_size=$(stat --printf="%s" "${file}")
    echo "Deploy ${file##*/} with ${file_size} bytes."
    lftools deploy maven-file "$MAVEN_REPO_URL" \
                              "$REPO_ID" \
                              "$file" \
                              -b "$MVN" \
                              -g "$GROUP_ID" \
                              -p "$MAVEN_OPTIONS $MAVEN_PARAMS" \
                              |& tee "$DEPLOY_LOG"
done < <(find "$UPLOAD_FILES_PATH" -xtype f -name "*")
