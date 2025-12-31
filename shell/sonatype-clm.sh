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
echo "---> sonatype-clm.sh"
# This script builds a Maven project and deploys it into a staging repo which
# can be used to deploy elsewhere later eg. Nexus staging / snapshot repos.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

export MAVEN_OPTS

# Determine CLM plugin version based on Java version
JAVA_VERSION=$(java -version 2>&1 | grep -i version | head -n 1 | sed 's/.*version "\(.*\)".*/\1/' | cut -d'.' -f1 | sed 's/^1\.//')

CLM_PLUGIN_VERSION='' # Leave empty to use latest version by default

if [[ "$JAVA_VERSION" -lt 17 ]]; then
    CLM_PLUGIN_VERSION="2.54.1-02"
fi

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN $MAVEN_GOALS dependency:tree com.sonatype.clm:clm-maven-plugin:${CLM_PLUGIN_VERSION}:index \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    -DaltDeploymentRepository=staging::file:"$WORKSPACE"/m2repo \
    $MAVEN_OPTIONS $MAVEN_PARAMS
