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

# Ensure we fail the job if any steps fail
set -eu -o pipefail

# Retrive OpenStack instace metadata APIs at this IP.
# The instance id and other metadata is useful for debugging VM.
curl -s http://169.254.169.254/openstack/latest/meta_data.json \
    | python -mjson.tool > "$WORKSPACE/archives/instance_meta_data.json"
