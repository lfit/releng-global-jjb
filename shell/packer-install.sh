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

# $PACKER_VERSION        : Define a packer version passed as job paramter

PACKER_VERSION="${PACKER_VERSION:-1.1.3}"
export PATH="${WORKSPACE}/bin:$PATH"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

if hash packer.io 2>/dev/null; then
    echo "packer.io command is available."
else
    echo "packer.io command not is available. Installing packer ..."
    # Installs Hashicorp's Packer binary, required for verify & merge packer jobs
    pushd "${WORKSPACE}"
    wget -nv "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    mkdir -p "${WORKSPACE}/bin"
    unzip "packer_${PACKER_VERSION}_linux_amd64.zip" -d "${WORKSPACE}/bin/"
    # rename packer to avoid conflict with binary in cracklib
    mv "${WORKSPACE}/bin/packer" "${WORKSPACE}/bin/packer.io"
    popd
fi
