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

os_cloud="${OS_CLOUD:-vex}"

set -eux -o pipefail

mapfile -t os_ports_ts < <(openstack --os-cloud "$os_cloud" port list -f value -c ID -c status -c created_at | grep -E DOWN | awk -F' ' '{print $1 " " $3}')

if [ ${#os_ports_ts[@]} -eq 0 ]; then
    echo "No orphaned ports found."
else
    for port_ts in "${os_ports_ts[@]}"; do
        echo "checking port uuid: ${port_ts#* } with TS: ${port_ts% *}"
        created_at_isots="${port_ts#* }"
        port_uuid="${port_ts% *}"
        created_at_uxts=$(date -d "${created_at_isots} - 30 minutes" +"%s")
        cutoff=$(date -d "30 minutes ago"  +%s)
        # Clean up ports where created_at > 30 minutes
        [ ${cutoff} -lt ${created_at_uxts} ] && continue
        echo "Removing orphaned port $port_uuid created_at ts > 30 minutes."
        openstack --os-cloud "$os_cloud" port delete "$port_uuid"
    done
fi
