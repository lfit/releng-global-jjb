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
echo "---> packer-validate.sh"
# The script validates an packers files.

# $CLOUDENV            :  Provides the cloud credential file.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

PACKER_LOGS_DIR="$WORKSPACE/archives/packer"
mkdir -p "$PACKER_LOGS_DIR"

cd packer
varfiles=(../packer/vars/*)
templates=(../packer/templates/*)

for varfile in "${varfiles[@]}"; do
    [[ "${varfile##*/}" =~ ^(cloud-env.*)$ ]] && continue
    for template in "${templates[@]}"; do
        export PACKER_LOG="yes" && \
        export PACKER_LOG_PATH="$PACKER_LOGS_DIR/packer-validate-${varfile##*/}-${template##*/}.log" && \
                    packer.io validate -var-file="$CLOUDENV" \
                    -var-file="$varfile" "$template"
        if [ $? -ne 0 ]; then
            break
        fi
    done
done
