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

set -o errexit
set -o nounset
set -o pipefail

# This script creates ArtifactPublishedEvent (APE)
# The JMS Messaging Plugin doesn't handle the newlines well so the eventBody is
# constructed on a single line. This is something that needs to be fixed properly

cat << EOF > $WORKSPACE/event.properties
type=$PUBLISH_EVENT_TYPE
origin=$PUBLISH_EVENT_ORIGIN
eventBody="{ 'type': '$PUBLISH_EVENT_TYPE', 'id': '$(uuidgen)', \
'time': '$(date -u +%Y-%m-%d_%H:%M:%SUTC)', 'origin': '$PUBLISH_EVENT_ORIGIN', \
'buildUrl': '$BUILD_URL', 'branch': 'master', 'artifactLocation': '$ARTIFACT_LOCATION', \
'confidenceLevel': { $CONFIDENCE_LEVEL } }"
EOF
echo "Constructed $PUBLISH_EVENT_TYPE"
echo "--------------------------------------------"
cat $WORKSPACE/event.properties
echo "--------------------------------------------"
