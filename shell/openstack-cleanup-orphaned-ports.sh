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

lf-activate-venv --python python3 \
    python-heatclient \
    python-openstackclient

set -eux -o pipefail

mapfile -t os_ports_ts < <(openstack --os-cloud "$os_cloud" port list \
        -f value \
        -c ID \
        -c status \
        -c created_at \
        | grep -E DOWN \
        | awk -F' ' '{print $1 " " $3}')

if [ ${#os_ports_ts[@]} -eq 0 ]; then
    echo "No orphaned ports found."
else
    cutoff=$(date -d "30 minutes ago"  +%s)
    for port_ts in "${os_ports_ts[@]}"; do
        created_at_isots="${port_ts#* }"
        port_uuid="${port_ts% *}"
        echo "checking port uuid: ${port_uuid} with TS: ${created_at_isots}"
        created_at_uxts=$(date -d "${created_at_isots}" +"%s")
        # Clean up ports where created_at > 30 minutes
        if [[ "$created_at_uxts" -gt "$cutoff" ]]; then
            echo "Removing orphaned port $port_uuid created_at ts > 30 minutes."
            openstack --os-cloud "$os_cloud" port delete "$port_uuid"
        fi
    done
fi
