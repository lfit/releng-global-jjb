#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

echo "---> capture-instance-metadata.sh"

# detect if we're in EC2
if [ -n "${NOMAD_DC}" ]; then
    echo "INFO: Running in Nomad, no metadata"
    exit 0
fi

if [[ ! -f /run/cloud-init/result.json ]]; then
    echo "INFO: Running in unsupported cloud, no metadata"
    exit 0
fi

# AWS not supported, exit
cloudtype="$(jq -r .v1.datasource /run/cloud-init/result.json)"
if [[ $cloudtype == "DataSourceEc2Local" ]]; then
   echo "INFO: Running in AWS, not capturing instance metadata"
   exit 0
fi

# Retrive OpenStack instace metadata APIs at this IP.
# The instance id and other metadata is useful for debugging VM.
echo "INFO: Running in OpenStack, capturing instance metadata"
curl -s http://169.254.169.254/openstack/latest/meta_data.json \
    | python -mjson.tool > "$WORKSPACE/archives/instance_meta_data.json"
