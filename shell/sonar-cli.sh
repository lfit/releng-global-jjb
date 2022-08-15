#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Non-Maven Sonar CLI
echo "---> sonar-cli.sh"

export SONAR_SCANNER_HOME=${WORKSPACE}/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-linux
curl --create-dirs -sSLo ${WORKSPACE}/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-linux.zip
unzip -o ${WORKSPACE}/.sonar/sonar-scanner.zip -d ${WORKSPACE}/.sonar/
export PATH=$SONAR_SCANNER_HOME/bin:$PATH
export ${SONAR_SCANNER_OPTS}

echo "Running sonar-scanner"
sonar-scanner \
  -Dsonar.organization=${sonarcloud-project-organization} \
  -Dsonar.projectKey=${sonarcloud-project-organization}_${sonarcloud-project-key} \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonarcloud.io
