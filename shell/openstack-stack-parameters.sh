#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> Create parameters file for OpenStack HOT"
stack_parameters="$WORKSPACE/stack-parameters.yaml"
tmp_params="$WORKSPACE/params.yaml"
JOB_SUM=$(echo "$JOB_NAME" | sum | awk '{{ print $1 }}')
VM_NAME="$JOB_SUM-$BUILD_NUMBER"

cat > "$tmp_params" << EOF
{openstack-heat-parameters}
job_name: '$VM_NAME'
silo: '$SILO'
EOF

echo "OpenStack Heat parameters generated"
echo "-----------------------------------"
echo "parameters:" > "$stack_parameters"
cat "$tmp_params" | sed 's/^/    /' >> "$stack_parameters"
cat "$stack_parameters"
rm "$tmp_params"
