#!/bin/bash
# @SPDX-License-Identifier: EPL-1.0
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

PACKER_VERSION="${PACKER_VERSION:-1.0.2}"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail
packer_bin="/usr/local/bin/packer.io"

if hash "$packer_bin" 2>/dev/null; then
    echo "packer.io command is available."
else
    echo "packer.io command not is available. Installing packer ..."
    # Installs Hashicorp's Packer binary, required for verify & merge packer jobs
    pushd packer
    wget --non-verbose "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"
    unzip "packer_${PACKER_VERSION}_linux_amd64.zip" -d /usr/local/bin/
    # rename packer to avoid conflict with binary in cracklib
    sudo mv /usr/local/bin/packer "$packer_bin"
    popd
fi
