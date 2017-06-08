#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
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

export MAVEN_OPTS

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN clean deploy \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    -DaltDeploymentRepository=staging::default::file:"$WORKSPACE"/m2repo \
    $MAVEN_PARAMS $MAVEN_OPTIONS
