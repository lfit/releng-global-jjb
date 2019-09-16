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
echo "---> whitesource-unified-agent-cli.sh"
# This script downloads wss-unified-agent-<version>.jar and uses it to perform
# a scan on the code whithin a repo based on the wss-unified-agent.config provided.

# DO NOT enable -u because $WSS_UNIFIED_AGENT_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -xe -o pipefail
set -u
echo "---> whitesource-unified-agent-cli.sh"
jar_location="/tmp/wss-unified-agent-${WSS_UNIFIED_AGENT_VERSION}.jar"
wss_unified_agent_url="https://s3.amazonaws.com/unified-agent/wss-unified-agent-${WSS_UNIFIED_AGENT_VERSION}.jar"
wget -nv "${wss_unified_agent_url}" -O "${jar_location}"
echo "---> Running WhiteSource Unified Agent CLI ..."
java ${JAVA_OPTS:-} -jar "${jar_location}" -c wss-unified-agent.config \
    -product "${WSS_PRODUCT_NAME}" -project "${WSS_PROJECT_NAME}" \
    -projectVersion "${GERRIT_BRANCH}" ${WSS_UNIFIED_AGENT_OPTIONS:-}
rm "${jar_location}"
