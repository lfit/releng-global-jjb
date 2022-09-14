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
echo "---> maven-javadoc-publish.sh"
# Publishes javadoc to a Maven project.

# DO NOT enable -u because $MAVEN_PARAMS and $MAVEN_OPTIONS could be unbound.
# Ensure we fail the job if any steps fail.
set -e -o pipefail
set +u

# shellcheck disable=SC1090
. ~/lf-env.sh

lf_activate_venv --python python3 lftools

JAVADOC_DIR="$WORKSPACE/archives/javadoc"

pushd "$JAVADOC_DIR"
zip -r "$WORKSPACE/javadoc.zip" .
popd

lftools deploy nexus-zip "$NEXUS_URL" "javadoc" "$DEPLOY_PATH" "$WORKSPACE/javadoc.zip"

# Tarball the javadoc dir and rm the directory to avoid re-upload into logs
pushd "$JAVADOC_DIR"
tar cvJf "$WORKSPACE/archives/javadoc.tar.xz" .
rm -rf "$JAVADOC_DIR"
popd
