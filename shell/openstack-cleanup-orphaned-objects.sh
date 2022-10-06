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
# Scans OpenStack for orphaned objects

# Script defaults to cleaning inactive ports older than 30 minutes

object="${OBJECT_TYPE:="port"}"
echo "---> Orphaned ${object}s"

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "lftools[openstack]" \
        python-openstackclient

os_cloud="${OS_CLOUD:-vex}"

set -eu -o pipefail

# Source age for deletion/removal from environment, otherwise use default value
age="${CLEANUP_AGE:="30 minutes ago"}"
echo "Cleanup age set to: ${age}"
current=$(date +%s)
cutoff=$(date -d "$age" +%s)

# Set filter/condition to match specific objects
attributes="${ATTRIBUTES:="-c status"}"
filters="${FILTERS:="grep -e DOWN"}"
echo "Object attributes: ${attributes}"
echo "Filters: ${filters}"

tmpfile=$(mktemp --suffix -openstack-${object}s.txt)
count_file=$(mktemp --suffix -openstack-${object}s-counter.txt)
timeout=180

_cleanup()
{
    uuid=$1
    created_at=$(openstack "${object}" show -f value -c created_at "$uuid")

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
    echo "$uuid" >> "$count_file"
}

# Output the initial list of objects to a temporary file
if [ -z "${filters}" ]; then
    # If a filter is specified
    openstack "${object}" list -f value -c ID "$attributes" | "$filters" > "$tmpfile"
else
    # Otherwise don't apply a pipe
    openstack "${object}" list -f value -c ID "$attributes" > "$tmpfile"
fi

# Count the number to process
total=$(wc -l "$tmpfile" | awk '{print $1}')
echo "Processing $total ${object} object(s); current time: $current age limit: $cutoff"

# Touch the counter file to avoid an intial word count error
touch "$count_file"

# A counter for the time spent spawning background processes
spawn_count=0

while read -r element; do
    # Spawn a background process for each query, run some queries in parallel
    id=$(echo "$element" | awk '{print $1}')
    _cleanup "$id" &
    # Sleep before spawning the next process
    # Avoid hitting the Openstack control plane too hard
    sleep 1
    spawn_count=$((spawn_count+1))
done < "$tmpfile"

# A counter for the time spent waiting for background processes to complete
sleep_count=0

while true; do
    # Increment counter; if the job takes too long, abort with error
    sleep 1
    sleep_count=$((sleep_count+1))
    if [ "$sleep_count" -gt "$timeout" ]; then
        rm "${tmpfile}" "${count_file}"
        echo "Error: job timeout $timeout reached!"; exit 1
    fi
    processed=$(wc -l "$count_file" | awk '{print $1}')
    if [ "$processed" -eq "$total" ]
    then
        time_taken=$((spawn_count + sleep_count))
        echo "All $object object(s) processed in $time_taken seconds"
        rm "${tmpfile}" "${count_file}"; exit 0
    fi
done
