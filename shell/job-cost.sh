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
echo "---> build-cost.sh"

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv python-openstackclient

if [[ -z ${JOB_NAME:-} ]]; then
    lf-echo-error "Required Env Variable Unset/Empty: JOB_NAME"
    exit 1
fi

# Get the cost of the Openstack agents. The 'stack-cost' file is created when
# the 'lftools openstack stack cost' command is called from
# 'openstack-stack-delete.sh' script. The 'stack-cost' file will only be created
# if this is an openstack job.
if [[ -f stack-cost ]]; then
    echo "DEBUG: $(cat stack-cost)"
    echo "INFO: Retrieving Stack Cost..."
    if ! stack_cost=$(fgrep "total: " stack-cost | awk '{print $2}'); then
        echo "ERROR: Unable to retrieve Stack Cost, continuing anyway"
        stack_cost=0
    fi
else
    echo "INFO: No Stack..."
    stack_cost=0
fi

# Retrieve the current uptime (in seconds)
uptime=$(awk '{print $1}' /proc/uptime)
# Convert to integer by truncating fractional part' and round up by one
((uptime=${uptime%\.*}+1))

instance_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)

echo "INFO: Retrieving Pricing Info for: $instance_type"
url="https://pricing.vexxhost.net/v1/pricing/$instance_type/cost?seconds=$uptime"
jason_block=$(curl -s $url)

cost=$(jq .cost <<< $jason_block)
resource=$(jq .resource <<< $jason_block | tr -d '"')

# Archive the cost date
mkdir -p $WORKSPACE/archives/cost

echo "INFO: Archiving Costs"

# Set the timestamp in GMT
# This format is readable by spreadsheet and is easily sortable
date=$(TZ=GMT date +'%Y-%m-%d %H:%M:%S')

cat << EOF > $WORKSPACE/archives/cost.csv
$JOB_NAME,$BUILD_NUMBER,$date,$resource,$uptime,$cost,$stack_cost
EOF

