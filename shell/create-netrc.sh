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
echo "---> create-netrc.sh"

if [ -z "$ALT_NEXUS_URL" ]; then
    NEXUS_URL="${NEXUSPROXY:-$NEXUS_URL}"
else
    NEXUS_URL="${ALT_NEXUS_URL}"
fi
CREDENTIAL=$(xmlstarlet sel -N "x=http://maven.apache.org/SETTINGS/1.0.0" \
    -t -m "/x:settings/x:servers/x:server[x:id='${SERVER_ID}']" \
    -v x:username -o ":" -v x:password \
    "$SETTINGS_FILE")

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

# Handle when a project chooses to not archive logs to a log server
# in other cases if CREDENTIAL is not found then fail the build.
if [ -z "$CREDENTIAL" ] && [ "$SERVER_ID" == "logs" ]; then
    echo "WARN: Log server credential not found."
    exit 0
elif [ -z "$CREDENTIAL" ]; then
    echo "ERROR: Credential not found."
    exit 1
fi

machine=$(echo "$NEXUS_URL" | awk -F/ '{print $3}')
user=$(echo "$CREDENTIAL" | cut -f1 -d:)
pass=$(echo "$CREDENTIAL" | cut -f2 -d:)

set +x  # Disable `set -x` to prevent printing passwords
echo "machine ${machine%:*} login $user password $pass" > ~/.netrc
