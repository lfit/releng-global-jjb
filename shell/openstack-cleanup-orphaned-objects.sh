#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Scans OpenStack environment for orphaned objects

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "lftools[openstack]" \
        python-openstackclient

set -eu -o pipefail

# OBJECT_TYPE is a mandatory external variable
object="${OBJECT_TYPE}"
echo "---> Orphaned Openstack ${object}s"

os_cloud="${OS_CLOUD:-vex}"

# Source age for deletion/removal from environment, otherwise use default value
age="${CLEANUP_AGE:="30 minutes ago"}"
echo "Cleanup age set to: ${age}"
current=$(date +%s)
cutoff=$(date -d "$age" +%s)

# Example attributes/filters to match orphaned port objects
# attributes="${ATTRIBUTES:="-c status"}"
# filters="${FILTERS:="grep -e DOWN"}"

# Set attributes/filters to match specific Openstack objects
attributes="${ATTRIBUTES:=""}"
filters="${FILTERS:=""}"
echo "Object attributes: ${attributes}"
echo "Filters: ${filters}"

tmpfile=$(mktemp --suffix -openstack-"${object}"s.txt)
threads=6

_cleanup()
{
    uuid=$1
    created_at=$(openstack --os-cloud "$os_cloud" "${object}" show -f value -c created_at "$uuid")

    if [ "$created_at" == "None" ]; then
        echo "No value for ${object} creation time; skipping: $uuid"
    else
        created_at_uxts=$(date -d "$created_at" +%s)

        # For debugging only; this outout usually disabled
        # echo "${uuid} created at ${created_at} / ${created_at_uxts} / cutoff: ${cutoff}"

        # Validate timing values are numeric
        if [[ "$created_at_uxts" -eq "$created_at_uxts" ]]; then
            # Clean up objects when created_at > specified age
            if [[ "$created_at_uxts" -lt "$cutoff" ]]; then
                echo "Removing orphaned ${object} $uuid created $created_at_uxts > $age"
                openstack --os-cloud "$os_cloud" "${object}" delete "$uuid"
            fi
        else
            echo "Date variable failed numeric test; deletion not possible"
        fi
    fi
}

# Output the initial list of object UUIDs to a temporary file
if [[ -n ${filters} ]]; then
    # If a filter/match condition is requested/set
    openstack --os-cloud "$os_cloud" "${object}" list -f value -c ID $attributes \
     | $filters | awk '{print $1}'> "$tmpfile"
else
    # Otherwise don't pipe through an additional command
    openstack --os-cloud "$os_cloud" "${object}" list -f value -c ID $attributes \
     | awk '{print $1}'> "$tmpfile"
fi

# Count the number of objects to process
total=$(wc -l "$tmpfile" | awk '{print $1}')
echo "Processing $total ${object} object(s); current time: $current age limit: $cutoff"

# Export variables and send to parallel for processing
export -f _cleanup
export os_cloud cutoff age object
# parallel --progress --retries 3 -j "$threads" _cleanup < "$tmpfile"
parallel --retries 3 -j "$threads" _cleanup < "$tmpfile"

rm "$tmpfile"
