#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> openstack-stack-delete.sh"

set -eufo pipefail

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
    lf-activate-venv --python python3 lftools[openstack] \
        python-heatclient \
        python-openstackclient
fi

echo "INFO: Retrieving stack cost for: $OS_STACK_NAME"
if ! lftools openstack --os-cloud "$OS_CLOUD" stack cost "$OS_STACK_NAME" > stack-cost; then
    echo "WARNING: Unable to get stack costs, continuing anyway"
    echo "total: 0" > stack-cost
else
    echo "DEBUG: Successfully retrieved stack cost: $(cat stack-cost)"
fi

# Delete the stack even if the stack-cost script fails
lftools openstack --os-cloud "$OS_CLOUD" stack delete "$OS_STACK_NAME" \
    | echo "INFO: $(cat)"
