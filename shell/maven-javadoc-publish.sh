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
# An agent's ~/lf-env.sh is copied when it boots, so may predate lftools-uv.
if ! declare -F lftools-uv > /dev/null; then
    lf_env="$(mktemp)"
    lf_env_url="https://raw.githubusercontent.com/lfit/releng-global-jjb"
    wget -nv -O "$lf_env" "$lf_env_url/${GLOBAL_JJB_VERSION:-master}/jenkins-init-scripts/lf-env.sh" || true
    # shellcheck disable=SC1090
    source "$lf_env"
    rm -f "$lf_env"
    if ! declare -F lftools-uv > /dev/null; then
        echo "ERROR: lf-env.sh has no lftools-uv function" >&2
        exit 1
    fi
fi

JAVADOC_DIR="$WORKSPACE/archives/javadoc"

pushd "$JAVADOC_DIR"
zip -r "$WORKSPACE/javadoc.zip" .
popd

lftools-uv deploy nexus-zip "$NEXUS_URL" "javadoc" "$DEPLOY_PATH" "$WORKSPACE/javadoc.zip"

# Tarball the javadoc dir and rm the directory to avoid re-upload into logs
pushd "$JAVADOC_DIR"
tar cvJf "$WORKSPACE/archives/javadoc.tar.xz" .
rm -rf "$JAVADOC_DIR"
popd
