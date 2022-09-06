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
# Scans OpenStack for orphaned ports
echo "---> Orphaned ports"

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "lftools[openstack]" \
        python-openstackclient

os_cloud="${OS_CLOUD:-vex}"

set -eu -o pipefail

tmpfile=$(mktemp --suffix -openstack-ports.txt)
count_file=$(mktemp --suffix -openstack-ports-counter.txt)
timeout=120

# Set age for deletion/removal
age="30 minutes ago"
cutoff=$(date -d "$age" +%s)

_cleanup()
{
    uuid=$1
    created_at=$(openstack --os-cloud "$os_cloud" port show -f value -c created_at "$uuid")

    if [ "$created_at" == "None" ]; then
        echo "No value for port creation time; skipping: $uuid"
    else
        created_at_uxts=$(date -d "$created_at" +"%s")

        # For debugging only; this outout usually disabled
        # echo "Port: ${uuid} created at ${created_at} / ${created_at_uxts}"

        # Validate timing values are numeric
        if [[ "$created_at_uxts" -eq "$created_at_uxts" ]]; then
            # Clean up ports where created_at > 30 minutes
            if [[ "$created_at_uxts" -lt "$cutoff" ]]; then
                echo "Removing orphaned port $uuid created > $age"
                openstack --os-cloud "$os_cloud" port delete "$uuid"
            fi
        else
            echo "Date variable failed numeric test; deletion not possible"
        fi
    fi
    echo "$uuid" >> "$count_file"
}

# Output the initial list of ports to a temporary file
openstack --os-cloud "$os_cloud" port list -f value -c ID -c status | grep -e DOWN > "$tmpfile"
# Count the number to process
total=$(wc -l "$tmpfile" | awk '{print $1}')
echo "Ports to process: $total; age limit: $cutoff"

# Touch the counter file to avoid an intial word count error
touch "$count_file"

# A counter for the time spent spawning background processes
spawn_count=0

while read -r row; do
    id=$(echo "$row" | awk '{print $1}')
    # Spawn a background process for each query, run some queries in parallel
    _cleanup "$id" &
    # Sleep before spawning the next process
    # Avoid hitting the Openstack control plane too hard
    sleep 1
    spawn_count=$((spawn_count+1))
done < "$tmpfile"

sleep_count=0

while true; do
    # Increment a counter; if the job takes too long, abort with error
    sleep 1
    sleep_count=$((sleep_count+1))
    if [ "$sleep_count" -gt "$timeout" ]; then
        echo "Error: job timeout $timeout reached"
        rm "${tmpfile}" "${count_file}"; exit 1
    fi
    processed=$(wc -l "$count_file" | awk '{print $1}')
    if [ "$processed" -eq "$total" ]
    then
        time_taken=$((spawn_count + sleep_count))
        echo "All ports processed in $time_taken seconds; completed"
        rm "${tmpfile}" "${count_file}"; exit 0
    fi
done
