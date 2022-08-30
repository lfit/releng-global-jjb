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

# Checks build-node labels used in ci-management templates and projects,
# and prints file names with invalid values.
#
# Uses -l to get $HOME/.local/bin on path, where pip puts yq
# Prereqs:
# - Bash version 3+
# - Python tool yq is installed; e.g., by python-tools-install.sh
# - Working directory is a ci-management repo with subdirs named below
# Environment variable:
# - EXTERNAL_LABELS - a space-separated list of build-node labels
#   for nodes not managed in the jenkins-config area (optional)

set -eu -o pipefail

# expected suffix on build-node config files
suffix=".cfg"
# subdir with cloud config files
configdir="jenkins-config/clouds/openstack"
# subdir with JJB yaml files
jjbdir="jjb"

# function to test if the argument is empty,
# is two double quotes, or has unwanted suffix
isBadLabel () {
    local label="$1"
    [[ -z "$label" ]] || [[ $label = "\"\"" ]] || [[ $label = *"$suffix" ]]
}

# function to search an array for a value
# $1 is value
# $2 is array, passed via ${array[@]}
isValueInArray () {
    local e match="$1"
    shift
    for e; do
        [[ "$e" == "$match" ]] && return 0
    done
    return 1
}

# check prereqs
if [ ! -d "$configdir" ] || [ ! -d "$jjbdir" ]; then
    echo "ERROR: failed to find subdirs $configdir and $jjbdir"
    exit 1
fi

# find cloud config node names by recursive descent
declare -a labels=()
while IFS= read -r ; do
    file="$REPLY"
    # valid files contain IMAGE_NAME; skip the cloud config file
    if grep -q "IMAGE_NAME" "$file" && ! grep -q "CLOUD_CREDENTIAL_ID" "$file"; then
        # file name without prefix or suffix is a valid label
        name=$(basename -s "$suffix" "$file")
        echo "INFO: add label $name for $file"
        labels+=("$name")
        # add custom labels from file
        if custom=$(grep "LABELS=" "$file" | cut -d= -f2); then
            # TODO: confirm separator for multiple labels
            read -r -a customarray <<< "$custom"
            for l in "${customarray[@]}"; do
                if isBadLabel "$l"; then
                    echo "WARN: skip custom label $l from $file"
                elif isValueInArray "$l" "${labels[@]}"; then
                    echo "INFO: skip repeat custom label $l from $file"
                else
                    echo "INFO: add custom label $l from $file"
                    labels+=("$l")
                fi
            done
        fi
    fi
done < <(find "$configdir" -name \*$suffix)

# add external build-node labels
if [[ -n ${EXTERNAL_LABELS:-} ]]; then
    read -r -a externals <<< "$EXTERNAL_LABELS"
    # defend against empty, quotes-only and repeated values
    for l in "${externals[@]}"; do
        if isBadLabel "$l"; then
            echo "WARN: skip external label $l"
        elif isValueInArray "$l" "${labels[@]}"; then
            echo "INFO: skip repeat label $l from environment"
        else
            echo "INFO: add label $l from environment"
            labels+=("$l")
        fi
    done
fi

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv yq

# show installed versions
python -m pip --version
python -m pip freeze

echo "INFO: label list has ${#labels[@]} entries:"
echo "INFO:" "${labels[@]}"

# check build-node label uses
count=0
errs=0
while IFS= read -r ; do
    file="$REPLY"
    echo "INFO: checking $file"
    # includes job-template AND project entries
    nodes=$(yq 'recurse | ."build-node"? | values' "$file" | sort -u | tr -d '"')
    # nodes may be a yaml list; e.g., '[ foo, bar, baz ]'
    for node in $nodes; do
        node="${node//[\[\],]/}"
        if [[ -n $node ]] && ! isValueInArray "$node" "${labels[@]}"; then
            echo "ERROR: unknown build-node $node in $file"
            errs=$((errs+1))
        else
            count=$((count+1))
        fi
    done
done < <(find "$jjbdir" -name '*.yaml')

echo "INFO: $count valid label(s), $errs invalid label(s)"
echo "---> jjb-verify-build-nodes.sh ends"
exit $errs
