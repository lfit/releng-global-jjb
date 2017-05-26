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
echo "---> create-netrc.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

NEXUS_URL="${NEXUS_URL:-$NEXUSPROXY}"
CREDENTIAL=$(xmlstarlet sel -N "x=http://maven.apache.org/SETTINGS/1.0.0" \
    -t -m "/x:settings/x:servers/x:server[x:id='${SERVER_ID}']" \
    -v x:username -o ":" -v x:password \
    "$SETTINGS_FILE")

machine=$(echo "$NEXUS_URL" | awk -F/ '{print $3}')
user=$(echo "$CREDENTIAL" | cut -f1 -d:)
pass=$(echo "$CREDENTIAL" | cut -f2 -d:)

echo "machine $machine login $user password $pass" > ~/.netrc
