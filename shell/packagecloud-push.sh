#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Prereqs:
# The build minion has the ruby gem "package_cloud"
# The required credentials and API files have been provisioned
# The build directory has .deb/.rpm files
# Environment variables:
# BUILD_DIR is set and non-empty
# DEBIAN_DISTRIBUTION_VERSIONS has distro list like "debian/stretch"
# RPM_DISTRIBUTION_VERSIONS has distro list like "el/4 el/5"
# PACKAGECLOUD_ACCOUNT is set and non-empty
# PACKAGECLOUD_REPO is a value like "staging"

echo "---> packagecloud-push.sh"
set -eu -o pipefail

# Pushes packages to PackageCloud
# $1 is a shell-style glob pattern for package files
# $2 is a space-separated list of distribution versions
push_packages () {
    echo "Expanding file pattern $1"
    # shellcheck disable=SC2206
    pkgs=($1)
    if [[ ! -f ${pkgs[0]} ]]; then
        echo "WARN: no files matched pattern $1"
        return
    fi
    echo "Found package file(s):" "${pkgs[@]}"
    echo "Processing distribution version(s): $2"
    for ver in $2; do
        arg="${PACKAGECLOUD_ACCOUNT}/${PACKAGECLOUD_REPO}/${ver}"
        for pkg in "${pkgs[@]}"; do
            echo "Pushing $arg $pkg"
            package_cloud push "$arg" "$pkg"
        done
    done
}

echo "Working in directory $BUILD_DIR"
cd "$BUILD_DIR"
push_packages "*.deb" "$DEBIAN_DISTRIBUTION_VERSIONS"
push_packages "*.rpm" "$RPM_DISTRIBUTION_VERSIONS"

echo "---> packagecloud-push.sh ends"
