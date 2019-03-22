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

set +x
echo "---> whitesource-unified-agent-cli.sh"
CLI_LOCATION="/tmp/wss-unified-agent-$WSS_UNIFIED_AGENT_VERSION.jar"
wget -nv https://s3.amazonaws.com/unified-agent/wss-unified-agent-$WSS_UNIFIED_AGENT_VERSION.jar -O $CLI_LOCATION
echo "---> Running WhiteSource Unified Agent CLI ..."
java -jar $CLI_LOCATION -c $WSS_UNIFIED_AGENT_CONFIG \
-product $WS_PRODUCT_NAME -project $WS_PROJECT_NAME \
$WSS_UNIFIED_AGENT_OPTIONS
rm $CLI_LOCATION
