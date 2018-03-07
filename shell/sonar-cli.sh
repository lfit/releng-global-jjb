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

# This script builds a Maven project and deploys it into a staging repo which
# can be used to deploy elsewhere later eg. Nexus staging / snapshot repos.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set +x

wget https://download.sonatype.com/clm/scanner/nexus-iq-cli-1.44.0-01.jar
java -jar nexus-iq-cli-1.44.0-01.jar -xc -i ${CLM_PROJECT_NAME} -s https://nexus-iq.wl.linuxfoundation.org -a ${CLM_USER}:${CLM_PASSWORD} -t build .
