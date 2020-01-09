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
echo "---> maven-javadoc-generate.sh"
# Generates javadoc in a Maven project.

# Ensure we fail the job if any steps fail.
# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
set -e -o pipefail
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
    -f "$MAVEN_DIR" \
    $MAVEN_OPTIONS $MAVEN_PARAMS

mv "$WORKSPACE/$MAVEN_DIR/target/site/apidocs" "$JAVADOC_DIR"

# TODO: Nexus unpack plugin throws a "504 gateway timeout" for jobs archiving
# large number of small files. Remove the workaround only we move away from
# using Nexus as the log server.
if [[ "$JOB_NAME" =~ "javadoc-verify" ]]; then
    # Tarball the javadoc dir and rm the directory to avoid re-upload into logs
    pushd "$JAVADOC_DIR"
    tar cvJf "$WORKSPACE/archives/javadoc.tar.xz" .
    rm -rf "$JAVADOC_DIR"
    popd
fi
