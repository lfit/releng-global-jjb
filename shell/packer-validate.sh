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
export PATH="${WORKSPACE}/bin:$PATH"

cd packer
varfiles=(vars/*.json common-packer/vars/*.json)
templates=(templates/*.json)

for varfile in "${varfiles[@]}"; do
    # cloud-env.json is a file containing credentials which is pulled in via
    # CLOUDENV variable so skip it here. Also handle the case where a project
    # has not vars/*.json file.
    if [[ "$varfile" == *"cloud-env.json"* ]] || [[ "$varfile" == 'vars/*.json' ]]; then
        continue
    fi

    echo "-----> Testing varfile: $varfile"
    for template in "${templates[@]}"; do
        export PACKER_LOG="yes"
        export PACKER_LOG_PATH="$PACKER_LOGS_DIR/packer-validate-${varfile##*/}-${template##*/}.log"
        if output=$(packer.io validate -var-file="$CLOUDENV" -var-file="$varfile" "$template"); then
            echo "$template: $output"
        else
            echo "$template: $output"
            exit 1
        fi
    done
done
