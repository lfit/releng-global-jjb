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

set -eux -o pipefail

mapfile -t os_ports_ts < <(openstack --os-cloud "$os_cloud" port list \
        -f value \
        -c ID \
        -c status \
        | grep -E DOWN )

if [ ${#os_ports_ts[@]} -eq 0 ]; then
    echo "No orphaned ports found."
else
    cutoff=$(date -d "30 minutes ago"  +%s)
    for port_ts in "${os_ports_ts[@]}"; do
        port_uuid="${port_ts% *}"
        echo "Retrieving timestamp for port uuid: ${port_uuid}"
        created_at=`openstack port show fc8789b7-06dc-40a8-8739-f06d472896d3 -f value -c created_at`
        created_at_uxts=$(date -d "${created_at}" +"%s")
        # Validate timestamp is numeric value
        if [[ "$created_at_uxts" -eq "$created_at_uxts" ]]; then
                # Clean up ports where created_at > 30 minutes
                if [[ "$created_at_uxts" -gt "$cutoff" ]]; then
                        echo "Removing orphaned port $port_uuid created_at ts > 30 minutes."
                        openstack --os-cloud "$os_cloud" port delete "$port_uuid"
                else
                        echo "Port did not meet requirement for deletion; moving on"
                fi
        else
                echo "Date variable failed numeric test; deletion not possible"
        fi
    done
fi
