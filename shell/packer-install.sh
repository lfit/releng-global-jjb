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
echo "---> packer-install.sh"
# The script checks for the packer binaries and installs the binary
# if its not available

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

# $PACKER_VERSION        : Define a packer version passed as job paramter
PACKER_VERSION="${PACKER_VERSION:-1.1.3}"
export PATH="${WORKSPACE}/bin:$PATH"

packer_install() {
    # Installs Hashicorp's Packer binary, required for verify & merge packer jobs
    pushd "${WORKSPACE}"
    wget -nv "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    mkdir -p "${WORKSPACE}/bin"
    unzip "packer_${PACKER_VERSION}_linux_amd64.zip" -d "${WORKSPACE}/bin/"
    # rename packer to avoid conflict with binary in cracklib
    mv "${WORKSPACE}/bin/packer" "${WORKSPACE}/bin/packer.io"
    popd
}

# Functions to compare semantic versions x.y.z
version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

if hash packer.io 2>/dev/null; then
    CURRENT_VERSION="$(packer.io --version)"
    if version_lt $CURRENT_VERSION $PACKER_VERSION; then
       echo "Packer version $CURRENT_VERSION installed is less than $PACKER_VERSION available, updating Packer."
       packer_install
    else
      echo "Packer version installed $CURRENT_VERSION is greater than or equal to the required minimum version $PACKER_VERSION."
    fi
else
    echo "Packer binary not available, installing Packer version $PACKER_VERSION."
    packer_install
fi
