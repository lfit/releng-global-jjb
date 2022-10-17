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
cores=$(nproc --all)
threads=$((3*cores))
regex_created_at='^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})Z$'

# Set age for deletion/removal
age="30 minutes ago"
cutoff=$(date -d "$age" +%s)

_cleanup()
{
    uuid=$1
    created_at=$(openstack --os-cloud "$os_cloud" port show -f value -c created_at "$uuid")
    
    if [ "$created_at" == "None" ]; then
        # This is a valid result for some objects; do not stop processing
        echo "No value for port creation time; skipping: $uuid"
        
    elif echo "$created_at" | grep -qP "$regex_created_at"; then
    
        created_at_uxts=$(date -d "$created_at" +"%s")

        # Cleanup objects where created_at is older than specified cutoff time
        # created_at_uxts is measured against UNIX epoch; lower values are older
        if [[ "$created_at_uxts" -lt "$cutoff" ]]; then
            echo "Removing orphaned port $uuid created $created_at_uxts > $age"
            openstack --os-cloud "$os_cloud" port delete "$uuid"
        fi
    else
        # Don't stop the job, but warn about unexpected value
        echo "Unknown/unexpected value for created_at: ${created_at}"
    fi
}

_rmtemp()
{
    if [ -f "$tmpfile" ]; then
        # Removes temporary file on script exit
        rm -f "$tmpfile"
    fi
}

trap _rmtemp EXIT

# Output the initial list of port UUIDs to a temporary file
openstack --os-cloud "$os_cloud" port list -f value -c ID -c status \
    | { grep -e DOWN || true; } | { awk '{print $1}' || true; } > "$tmpfile"

# Count the number to process
total=$(wc -l "$tmpfile" | awk '{print $1}')

if [ "$total" -eq 0 ]; then
    echo "No orphaned ports to process."
    exit 0
fi

echo "Ports to process: $total; age limit: $cutoff"
echo "Using $threads parallel processes..."

# Export variables and send to parallel for processing
export -f _cleanup
export os_cloud cutoff age
parallel --progress --retries 3 -j "$threads" _cleanup < "$tmpfile"
