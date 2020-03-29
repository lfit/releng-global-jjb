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
echo "---> jjb-verify-build-nodes.sh"

# Checks build-node labels used in ci-management job definitions
# Requires -l to get $HOME/bin in path where yq is installed
# Prereqs:
# Python CLI yq is available; e.g., from python-tools-install.sh.
# Working directory is a ci-management repo with a jjb subdir and
# a jenkins-config/clouds/openstack subdir.

set -eu -o pipefail

# function to search an array for a value
# $1 is value
# $2 is array, passed via ${array[@]}
isValueInArray () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# discover build node labels
labels=()
suffix=".cfg"
while IFS= read -r ; do
    file="$REPLY"
    # valid files contain IMAGE_NAME; skip the cloud config file
    if grep -q "IMAGE_NAME" "$file" && ! grep -q "CLOUD_CREDENTIAL_ID" "$file"; then
        # strip prefix and suffix
        label=$(basename -s "$suffix" "$file")
        labels+=("$label")
    fi
done < <(find "jenkins-config/clouds/openstack" -name \*$suffix)
if (( ${#labels[@]} == 0 )); then
    echo "ERROR: found no node config files"
    exit 1
fi
echo "Found ${#labels[@]} build-node labels:"
echo "${labels[@]}"

# check build node label uses
errs=0
while IFS= read -r ; do
    file="$REPLY"
    echo "Checking $file"
    nodes=$(yq 'recurse | ."build-node"? | values' "$file" | sort -u | tr -d '"')
    for node in $nodes; do
        if ! isValueInArray "$node" "${labels[@]}"; then
            echo "ERROR: file $file uses unknown build-node $node"
            errs=$((errs+1))
        fi
    done
done < <(find "jjb" -name '*.yaml')

echo "---> jjb-verify-build-nodes.sh ends"
# a non-zero value means failure
exit "$errs"
