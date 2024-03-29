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

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN $MAVEN_GOALS dependency:tree com.sonatype.clm:clm-maven-plugin:2.41.0-02:index \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    -DaltDeploymentRepository=staging::default::file:"$WORKSPACE"/m2repo \
    $MAVEN_OPTIONS $MAVEN_PARAMS
