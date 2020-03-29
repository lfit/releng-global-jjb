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

# Checks build-node labels used in ci-management job definitions and
# prints the file names with invalid values.
# Not completely watertight; for example, does not detect a project
# with no build node using a template with an invalid build node.
#
# Uses -l to get $HOME/.local/bin on path, where pip puts yq
# Prereqs:
# - Bash version 3+
# - Python tool yq is installed; e.g., by python-tools-install.sh
# - Working directory is a ci-management repo with subdirs
#   jenkins-config/clouds/openstack and jjb
# Environment variable:
# - EXTERNAL_LABELS - a space-separated list of build-node labels
#   for nodes not managed in the jenkins-config area (optional)

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
declare -a labels=()
suffix=".cfg"
while IFS= read -r ; do
    file="$REPLY"
    # valid files contain IMAGE_NAME; skip the cloud config file
    if grep -q "IMAGE_NAME" "$file" && ! grep -q "CLOUD_CREDENTIAL_ID" "$file"; then
        # file name is a valid label, without path prefix and suffix
        name=$(basename -s "$suffix" "$file")
        labels+=("$name")
        # a file can define custom labels
        if custom=$(grep "LABELS=" "$file" | cut -d= -f2); then
            # TODO: confirm separator for multiple labels
            read -r -a customarray <<< "$custom"
            for c in "${customarray[@]}"; do
                if ! isValueInArray "$c" "${labels[@]}"; then
                    labels+=("$c")
                fi
            done
        fi
    fi
done < <(find "jenkins-config/clouds/openstack" -name \*$suffix)
echo "Found ${#labels[@]} configured label(s):"
echo "${labels[@]}"
declare -a externals=()
if [[ -n ${EXTERNAL_LABELS:-} ]]; then
    read -r -a externals <<< "$EXTERNAL_LABELS"
    echo "Received ${#externals[@]} external label(s):"
    echo "${externals[@]}"
    labels=("${externals[@]}" "${labels[@]}")
fi

# check build node label uses
errs=0
while IFS= read -r ; do
    file="$REPLY"
    echo "Checking $file"
    # match project/*/build-node entries; this excludes job-templates
    nodes=$(yq 'recurse | ."project"? | ."build-node"? | values' "$file" | sort -u | tr -d '"')
    for node in $nodes; do
        if ! isValueInArray "$node" "${labels[@]}"; then
            echo "ERROR: file $file uses unknown build-node $node"
            errs=$((errs+1))
        fi
    done
done < <(find "jjb" -name '*.yaml')

echo "---> jjb-verify-build-nodes.sh ends"
exit $errs
