#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> maven-build.sh"
# This script builds a Maven project and deploys it into a staging repo which
# can be used to deploy elsewhere later eg. Nexus staging / snapshot repos.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -xe -o pipefail
set +u

# Determine deployment repository format based on maven-deploy-plugin version
# Version 3+ uses simplified format without ::default::
plugin_version=$($MVN help:describe -Dplugin=org.apache.maven.plugins:maven-deploy-plugin -Ddetail \
    --global-settings "$GLOBAL_SETTINGS_FILE" 2>/dev/null \
    | grep "^Version:" | awk '{print $2}' || echo "2.8.2")

if [[ "$plugin_version" -lt "3" ]]; then
  # Disable SC2016 because we don't want $WORKSPACE to be expanded here.
  # shellcheck disable=SC2016
  alt_repo='-DaltDeploymentRepository=staging::default::file:"$WORKSPACE"/m2repo'
else
  # Disable SC2016 because we don't want $WORKSPACE to be expanded here.
  # shellcheck disable=SC2016
  # Disable SC2089 because the embedded quotes are intentional.
  # shellcheck disable=SC2089
  alt_repo='-DaltDeploymentRepository=staging::file:"$WORKSPACE"/m2repo'
fi

export MAVEN_OPTS

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN $MAVEN_GOALS \
    -e \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    # Disable SC2090 because the embedded quotes are intentional.
    # shellcheck disable=SC2090
    $alt_repo \
    $MAVEN_OPTIONS $MAVEN_PARAMS
