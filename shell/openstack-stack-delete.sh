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

time lf-activate-venv lftools[openstack] python-openstackclient

echo "Retrieving Stack Costs for: $OS_STACK_NAME"
stack_cost_script="/opt/ciman/global-jjb/shell/openstack-stack-cost.py"
python --version
python $stack_cost_script $OS_STACK_NAME || true

echo "Deleting $OS_STACK_NAME"
lftools openstack --os-cloud "$OS_CLOUD" stack delete "$OS_STACK_NAME"
