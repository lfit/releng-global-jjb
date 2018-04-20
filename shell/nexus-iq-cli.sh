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

# This script downloads nexus-iq-cli-1.44.0-01.jar and uses it to perform an
# XC Evaluation or extended report which provides a scan of python files within
# the repo

set +x
CLI_LOCATION="/tmp/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar"
wget -nv https://download.sonatype.com/clm/scanner/nexus-iq-cli-${NEXUS_IQ_CLI_VERSION}.jar -O ${CLI_LOCATION}
echo "-a" > cli-auth.txt
echo "${CLM_USER}:${CLM_PASSWORD}" >> cli-auth.txt
java -jar ${CLI_LOCATION} @cli-auth.txt -xc -i ${CLM_PROJECT_NAME} -s https://nexus-iq.wl.linuxfoundation.org -t build .
rm cli-auth.txt
rm ${CLI_LOCATION}