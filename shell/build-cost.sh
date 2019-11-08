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

set -eu -o pipefail -o noglob

# Retrieve the current uptime (in seconds)
uptime=$(cat /proc/uptime | awk '{print $1}')
# Convert to integer by truncating fractional part' and round up by one
((uptime=${uptime%\.*}+1))

echo "Retrieving Instance Type.."
instance_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)

echo "Retrieving Pricing Info for: $instance_type"
url="https://pricing.vexxhost.net/v1/pricing/$instance_type/cost?seconds=$uptime"
jason_block=$(curl -s $url)
cost=$(jq .cost <<< $jason_block)
resource=$(jq .resource <<< $jason_block | tr -d '"')

mkdir -p $WORKSPACE/archives/cost

echo "Archiving results"
# Human readable
cat << EOF > $WORKSPACE/archives/cost/cost.txt
Date          = $(date)
JOB_NAME      = $JOB_NAME
Uptime        = $uptime
Resource      = $resource
Cost          = $cost
EOF

# Bash
cat << EOF > $WORKSPACE/archives/cost/cost.sh
#!/usr/bin/no-execute
lf_date=$(date)
lf_job_name=$JOB_NAME
lf_uptime=$uptime
lf_resource=$resource
lf_cost=$cost
EOF

# JSON
# Add some new entries to the JSON Block returned by curl
# I chose to quote the keys/values to be consistent with what curl generated
# JSON does not require them and we could go either way
# A quoting 'adventure' awaits
cat <<< $jason_block \
    | jq '. | .["jobname"]="'"$JOB_NAME"'" | .["uptime"]='$uptime'' \
    | jq '. | .["date"]="'"$(date)"'" | .["epoch"]='"$(date +%s)"'' \
         > $WORKSPACE/archives/cost/cost.json
