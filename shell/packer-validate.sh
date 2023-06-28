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

# Functions to compare semantic versions x.y.z
version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

PACKER_LOGS_DIR="$WORKSPACE/archives/packer"
mkdir -p "$PACKER_LOGS_DIR"
export PATH="${WORKSPACE}/bin:$PATH"
set -x
cd packer

if version_ge "$PACKER_VERSION" "1.9.0"; then
    varfiles=(vars/*.pkrvars.hcl common-packer/vars/*.pkrvars.hcl)
    templates=(templates/*.pkr.hcl)
else
    varfiles=(vars/*.json common-packer/vars/*.json)
    templates=(templates/*.json)
fi

for varfile in "${varfiles[@]}"; do
    # cloud-env.{json,pkrvars.hcl} is a file containing credentials which is
    # pulled in via CLOUDENV variable so skip it here. Also handle case
    # where a project does not vars/*.{json,pkrvars.hcl} file.
    if [[ "$varfile" == *"cloud-env.json"* ]] || \
       [[ "$varfile" == "vars/*.json" ]] || \
       [[ "$varfile" == *"cloud-env.pkrvars.hcl"* ]] || \
       [[ "$varfile" == *"cloud-env-aws.pkrvars.hcl"* ]] || \
       [[ "$varfile" == "vars/*.pkrvars.hcl" ]]; then
        continue
    fi

    echo "-----> Testing varfile: $varfile"
    for template in "${templates[@]}"; do
        if [[ "$template" == *"variables.pkr.hcl"* ]] || \
           [[ "$template" == *"variables.auto.pkr.hcl"* ]]; then
            continue
        fi

        if [[ "${template#*.}" == "pkr.hcl" ]]; then
            echo "packer init $template ..."
            packer.io init "$template"
        fi

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
