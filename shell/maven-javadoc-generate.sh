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

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -xe -o pipefail
set +u

JAVADOC_DIR="$WORKSPACE/archives/javadoc"
mkdir -p "$WORKSPACE/archives"

export MAVEN_OPTS

# Warn if -f occurs in options or params but don't fail
if [[ $MAVEN_OPTIONS =~ "-f" || $MAVEN_PARAMS =~ "-f" ]]; then
    echo "WARNING: found -f which may conflict with MAVEN_DIR"
    echo "WARNING: MAVEN_OPTIONS has: $MAVEN_OPTIONS"
    echo "WARNING: MAVEN_PARAMS has: $MAVEN_PARAMS"
fi

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
