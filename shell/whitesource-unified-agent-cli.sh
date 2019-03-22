#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This script downloads wss-unified-agent-<version>.jar and uses it to perform
# a scan on the code whithin a repo based on the wss-unified-agent.config provided.

set -ue -o pipefail
echo "---> whitesource-unified-agent-cli.sh"
jar_location="/tmp/wss-unified-agent-$WSS_UNIFIED_AGENT_VERSION.jar"
wget -nv https://s3.amazonaws.com/unified-agent/wss-unified-agent-$WSS_UNIFIED_AGENT_VERSION.jar -O $jar_location
echo "---> Running WhiteSource Unified Agent CLI ..."
java -jar $jar_location -c $WSS_UNIFIED_AGENT_CONFIG \
    -product $WSS_PRODUCT_NAME -project $WSS_PROJECT_NAME \
    $WSS_UNIFIED_AGENT_OPTIONS-
rm $jar_location
