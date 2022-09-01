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

os_cloud="${OS_CLOUD:-vex}"

set -eux -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh
# Check if openstack venv was previously created
if [ -f "/tmp/.os_lf_venv" ]; then
    os_lf_venv=$(cat "/tmp/.os_lf_venv")
fi

if [ -d "${os_lf_venv}" ] && [ -f "${os_lf_venv}/bin/openstack" ]; then
    echo "Re-use existing venv: ${os_lf_venv}"
    PATH=$os_lf_venv/bin:$PATH
else
    lf-activate-venv --python python3 "cryptography<3.4" \
        "lftools[openstack]" \
        kubernetes \
        "niet~=1.4.2" \
        python-heatclient \
        python-openstackclient \
        python-magnumclient \
        setuptools \
        "openstacksdk<0.99" \
        yq
fi
mapfile -t os_volumes < <(openstack --os-cloud "$os_cloud" volume list -f value -c ID --status Available)

if [ ${#os_volumes[@]} -eq 0 ]; then
    echo "No orphaned volumes found."
else
    for volume in "${os_volumes[@]}"; do
        echo "Removing volume $volume"
        lftools openstack --os-cloud "$os_cloud" volume remove --minutes 15 "$volume"
    done
fi
