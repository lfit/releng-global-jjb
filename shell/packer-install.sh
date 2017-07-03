#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
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
packer_bin="/usr/local/bin/packer.io"


if hash "$packer_bin" 2>/dev/null; then
    echo "packer.io command is available."
else
    echo "packer.io command not is available. Installing packer ..."
    # Installs Hashicorp's Packer binary, required for verify & merge packer jobs
    mkdir /tmp/packer
    cd /tmp/packer
    wget https://releases.hashicorp.com/packer/1.0.2/packer_1.0.2_linux_amd64.zip
    unzip packer_1_0.2_linux_amd64.zip -d /usr/local/bin/
    # rename packer to avoid conflict with binary in cracklib
    mv /usr/local/bin/packer "$packer_bin"
fi
