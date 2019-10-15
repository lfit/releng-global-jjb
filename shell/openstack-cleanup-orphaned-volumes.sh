#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Scans OpenStack for orphaned volumes
echo "---> Orphaned volumes"

# Reuse the python-virtualenv.sh venv
venv=/tmp/virtualenv
PATH=$venv/bin:$PATH

os_cloud="${OS_CLOUD:-vex}"

set -eux -o pipefail

mapfile -t os_volumes < <(openstack --os-cloud "$os_cloud" volume list -f value -c ID --status Available)

if [ ${#os_volumes[@]} -eq 0 ]; then
    echo "No orphaned volumes found."
else
    for volume in "${os_volumes[@]}"; do
        echo "Removing volume $volume"
        lftools openstack --os-cloud "$os_cloud" volume remove --minutes 15 "$volume"
    done
fi
