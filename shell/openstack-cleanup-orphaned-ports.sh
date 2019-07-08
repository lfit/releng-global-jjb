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
# Scans OpenStack for orphaned port
echo "---> Orphaned ports"

os_cloud="${OS_CLOUD:-vex}"

set -eux -o pipefail

mapfile -t os_ports < <(openstack --os-cloud "$os_cloud" port list -f value -c ID -c status | egrep DOWN | awk '{print $1}')

if [ ${#os_ports[@]} -eq 0 ]; then
    echo "No orphaned ports found."
else
    for port in "${os_ports[@]}"; do
        echo "Removing orphaned port $port"
        openstack --os-cloud "$os_cloud" port delete "$port"
    done
fi
