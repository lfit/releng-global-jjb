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
# An agent's ~/lf-env.sh is copied when it boots, so may predate lftools-uv.
if ! declare -F lftools-uv > /dev/null; then
    lf_env="$(mktemp)"
    lf_env_url="https://raw.githubusercontent.com/lfit/releng-global-jjb"
    wget -nv -O "$lf_env" "$lf_env_url/${GLOBAL_JJB_VERSION:-master}/jenkins-init-scripts/lf-env.sh" || true
    # shellcheck disable=SC1090
    source "$lf_env"
    rm -f "$lf_env"
    if ! declare -F lftools-uv > /dev/null; then
        echo "ERROR: lf-env.sh has no lftools-uv function" >&2
        exit 1
    fi
fi

lf-activate-venv --python python3 kubernetes \
    niet \
    python-heatclient \
    python-openstackclient \
    python-magnumclient \
    yq

mapfile -t os_volumes < <(openstack --os-cloud "$os_cloud" volume list -f value -c ID --status Available)

if [ ${#os_volumes[@]} -eq 0 ]; then
    echo "No orphaned volumes found."
else
    for volume in "${os_volumes[@]}"; do
        echo "Removing volume $volume"
        lftools-uv openstack --os-cloud "$os_cloud" volume remove --minutes 15 "$volume"
    done
fi
