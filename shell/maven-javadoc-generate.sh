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

# Generates javadoc in a Maven project.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -xe -o pipefail
set +u

JAVADOC_DIR="$WORKSPACE/archives/javadoc"
mkdir -p "$WORKSPACE/archives"

export MAVEN_OPTS

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN clean install javadoc:aggregate \
    -e -Pq -Dmaven.javadoc.skip=false \
    -DskipTests=true \
    -Dcheckstyle.skip=true \
    -Dfindbugs.skip=true \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    $MAVEN_OPTIONS $MAVEN_PARAMS

mv "$WORKSPACE/target/site/apidocs" "$JAVADOC_DIR"
