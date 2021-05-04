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
echo "---> maven-javadoc-generate.sh"
# Generates javadoc in a Maven project.

# Ensure we fail the job if any steps fail.
# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
set -e -o pipefail
set +u

JAVADOC_DIR="$WORKSPACE/archives/javadoc"
mkdir -p "$WORKSPACE/archives"

export MAVEN_OPTS

# use absolute path as workaround for javadoc:aggregate
# silent failure on relative path, for example "-f ."
maven_dir_abs=$(readlink -f "$MAVEN_DIR")

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
# Use -x via subshell to show maven invocation details in the log
(set -x
    $MVN clean install javadoc:aggregate \
        -f "$maven_dir_abs" \
        -e -Pq -Dmaven.javadoc.skip=false \
        -DskipTests=true \
        -Dcheckstyle.skip=true \
        -Dfindbugs.skip=true \
        --global-settings "$GLOBAL_SETTINGS_FILE" \
        --settings "$SETTINGS_FILE" \
        $MAVEN_OPTIONS $MAVEN_PARAMS
)

mv "$WORKSPACE/$MAVEN_DIR/target/site/apidocs" "$JAVADOC_DIR"

# TODO: Nexus unpack plugin throws a "504 gateway timeout" for jobs archiving
# large number of small files. Remove the workaround when we move away from
# using Nexus as the log server.
if [[ "$JOB_NAME" =~ "javadoc-verify" ]]; then
    # Tarball the javadoc dir and rm the directory to avoid re-upload into logs
    tarball="$WORKSPACE/archives/javadoc.tar.xz"
    echo "INFO: archiving $JAVADOC_DIR as $tarball"
    pushd "$JAVADOC_DIR"
    tar cvJf "$tarball" .
    popd
    rm -rf "$JAVADOC_DIR"
fi
