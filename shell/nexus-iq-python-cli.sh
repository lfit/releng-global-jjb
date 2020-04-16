#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> nexus-iq-python-cli.sh"
# This script downloads the specified version of the nexus-iq-cli jar, uses it
# to perform an XC Evaluation or extended report which provides a scan of python
# files within the repo starting at the root, then publishes the result to an LF
# server using the specified credentials.

# stop on error or unbound variable
set -eu
# do not print commands, credentials should not be logged
set +x
CLI_LOCATION="/tmp/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar"
echo "INFO: downloading nexus-iq-cli version $NEXUS_IQ_CLI_VERSION"
wget -nv "https://download.sonatype.com/clm/scanner/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar" -O "${CLI_LOCATION}"
echo "-a" > cli-auth.txt
echo "${CLM_USER}:${CLM_PASSWORD}" >> cli-auth.txt
echo "INFO: running nexus-iq-cli scan on project $CLM_PROJECT_NAME"

#Generate a requirements.txt
source ~/lf-env.sh
pip freeze > requirements.txt

java -jar "${CLI_LOCATION}" @cli-auth.txt -i "${CLM_PROJECT_NAME}" -r result.json -s https://nexus-iq.wl.linuxfoundation.org -t build requirements.txt
rm cli-auth.txt
rm "${CLI_LOCATION}"

echo "---> nexus-iq-python-cli.sh ends"
