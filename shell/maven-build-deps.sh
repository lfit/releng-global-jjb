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

# Builds projects provided via $DEPENDENCY_BUILD_ORDER list
#
# This runs a `mvn clean install` against all projects provided by a list. This
# script is a companion script for the gerrit-fetch-dependencies script which
# clones project repos to "$WORKSPACE/.repos".

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

IFS=" " read -r -a PROJECTS <<< "$DEPENDENCY_BUILD_ORDER"
REPOS_DIR="$WORKSPACE/.repos"

export MAVEN_OPTS

for project in "${PROJECTS[@]}"; do
    pushd "$REPOS_DIR/$project"
    # Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
    # shellcheck disable=SC2086
    $MVN clean install \
        -e -Pq \
        -DskipTests=true \
        --global-settings "$GLOBAL_SETTINGS_FILE" \
        --settings "$SETTINGS_FILE" \
        $MAVEN_OPTIONS $MAVEN_PARAMS
    popd
done
