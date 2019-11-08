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

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv lftools[openstack] python-openstackclient

echo "INFO: Retrieving stack cost for: $OS_STACK_NAME"
# The build sources may not include a global-jjb clone, so we need to run this
# script from the clone created by Jenkins Init Scripts (/opt/ciman).
stack_cost_script="/opt/ciman/global-jjb/shell/openstack-stack-cost.py"
if ! python $stack_cost_script $OS_STACK_NAME > stack-cost; then
    echo "WARNING: Unable to get stack costs, continuing anyway"
    echo "total: Unknown" > stack-cost
else
    echo "INFO: Successfully retrieved stack cost: $(cat stack-cost)"
fi

lftools openstack --os-cloud "$OS_CLOUD" stack delete "$OS_STACK_NAME" \
        | echo "INFO: $(cat)"
