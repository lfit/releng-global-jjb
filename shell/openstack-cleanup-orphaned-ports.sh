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

os_cloud="${OS_CLOUD:-vex}"

# Check if openstack venv was previously created
if [ -f "/tmp/.os_lf_venv" ]; then
    os_lf_venv=$(cat "/tmp/.os_lf_venv")
fi

if [ -d "${os_lf_venv}" ] && [ -f "${os_lf_venv}/bin/openstack" ]; then
    echo "Re-use existing venv: ${os_lf_venv}"
    PATH=$os_lf_venv/bin:$PATH
else
    lf-activate-venv --python python3 \
        python-heatclient \
        python-openstackclient
fi

set -eu -o pipefail

tmpfile=/tmp/openstack-ports.txt
counter=0
count_file=/tmp/openstack-ports-counter.txt
timeout=120

# Set age for deletion/removal
age="30 minutes ago"
cutoff=$(date -d "$age" +%s)

_remove_port()
{
    port_uuid=$1
    created_at=$(openstack port show -f value -c created_at "$port_uuid")
    
    if [ "$created_at" == "None" ]; then
        echo "No value for port creation time; skipping: $port_uuid"
        echo "$port_uuid" >> "$count_file"
    else
        created_at_uxts=$(date -d "$created_at" +"%s")
                
        # echo "Port: ${port_uuid} created at ${created_at} / ${created_at_uxts}"
    
        # Validate dates are numeric and non-zero
        if [[ "$created_at_uxts" -eq "$created_at_uxts" ]]; then
            # Clean up ports where created_at > 30 minutes
            if [[ "$created_at_uxts" -gt "$cutoff" ]]; then
                echo "Removing orphaned port $port_uuid created > $age"
                # openstack --os-cloud "$os_cloud" port delete "$port_uuid"
            fi
        else
            echo "Date variable failed numeric test; deletion not possible"
        fi
        echo "$port_uuid" >> "$count_file"
    fi
}

if [ -f "$count_file" ]; then
    echo "Removing previous counter file"
    rm "$count_file"
fi

# Output the initial list of ports to a temporary file
openstack port list -f value -c ID > "$tmpfile"
# Count the number to process
total=$(cat "$tmpfile" | wc -l)
echo "Ports to process: $total; age limit: $cutoff"

# Touch the counter file to avoid an intial word count error
touch "$count_file"

# A counter for the time spent spawning background processes
spawn_counter=0

while read port; do
    # Spawn a background process for each query, run some queries in parallel
    _remove_port "$port" &
    # Sleep before spawning the next process
    # Avoid hitting the Openstack control plane too hard
    sleep 1
    spawn_counter=$(expr "$spawn_counter" + 1)
done < "$tmpfile"

sleep_count=0

while true; do
    # Increment a counter; if the job takes too long, abort with error
    sleep 1
    sleep_count=$(expr "$sleep_count" + 1)
    if [ "$sleep_count" -gt "$timeout" ]; then
        echo "Error: job timeout $timeout reached"; exit 1
    fi
    processed=$(cat "$count_file" | wc -l)
    if [ "$processed" -eq "$total" ]
    then
        rm "$tmpfile" "$count_file" >/dev/null 2>&1
        time_taken=$(expr "$spawn_counter" + "$sleep_count")
        echo "All ports processed in $time_taken seconds; completed"; exit 0
    fi
done
