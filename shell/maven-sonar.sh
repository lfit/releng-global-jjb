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
echo "---> maven-sonar.sh"
# This script builds a Maven project and deploys it into a staging repo which
# can be used to deploy elsewhere later eg. Nexus staging / snapshot repos.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -xe -o pipefail
set +u

export MAVEN_OPTS

declare -a params
params+=("--global-settings $GLOBAL_SETTINGS_FILE")
params+=("--settings $SETTINGS_FILE")

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
_JAVA_OPTIONS="$JAVA_OPTS" $MVN $MAVEN_GOALS \
    -e -Dsonar \
    ${params[*]} \
    $MAVEN_OPTIONS $MAVEN_PARAMS

if [ "$SONAR_HOST_URL" = "https://sonarcloud.io" ]; then
    params+=("-Dsonar.projectKey=$PROJECT_KEY")
    params+=("-Dsonar.organization=$PROJECT_ORGANIZATION")
    params+=("-Dsonar.login=$API_TOKEN")
    if [[ "$USE_SHORT_LIVED_BRANCH" == True ]]; then
        echo "Will scan short lived branch ..."
	if [ ! -z ${GERRIT_CHANGE_NUMBER+x} ]; then
            GERRIT_SHORT_LIVED_BRANCH=${GERRIT_CHANGE_NUMBER}-${GERRIT_PATCHSET_NUMBER}
            params+=("-Dsonar.analysis.gerritProjectName=$PROJECT")
            params+=("-Dsonar.branch.target=$GERRIT_BRANCH")
            params+=("-Dsonar.branch.name=$GERRIT_SHORT_LIVED_BRANCH")
	fi
    fi
fi

if [ "$SET_JDK_VERSION" != "$SONARCLOUD_JAVA_VERSION" ]; then
    export SET_JDK_VERSION="$SONARCLOUD_JAVA_VERSION"
    bash <(curl -s https://raw.githubusercontent.com/lfit/releng-global-jjb/master/shell/update-java-alternatives.sh)
    source /tmp/java.env
fi

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
"$MVN" $SONAR_MAVEN_GOAL \
    -e -Dsonar -Dsonar.host.url="$SONAR_HOST_URL" \
    ${params[*]} \
    $MAVEN_OPTIONS $MAVEN_PARAMS
