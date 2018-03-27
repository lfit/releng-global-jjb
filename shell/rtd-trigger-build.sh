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
echo "---> rtd-trigger-build.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u
set -xe -o pipefail

if [ "$GERRIT_BRANCH" == "master" ]; then
    RTD_BUILD_VERSION=latest
else
    RTD_BUILD_VERSION="${GERRIT_BRANCH/\//-}"
fi

CREDENTIAL=$(xmlstarlet sel -N "x=http://maven.apache.org/SETTINGS/1.0.0" \
    -t -m "/x:settings/x:servers/x:server[x:id='${SERVER_ID}']" \
    -v x:username -o ":" -v x:password \
    "$GLOBAL_SETTINGS_FILE")

RTD_BUILD_TOKEN=$(echo "$CREDENTIAL" | cut -f2 -d:)

curl -X POST -d "branches=$RTD_BUILD_VERSION" -d "token=$RTD_BUILD_TOKEN" "$RTD_BUILD_URL"

