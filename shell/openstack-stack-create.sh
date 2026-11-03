#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017, 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> Create HEAT stack"

os_cloud="${OS_CLOUD:-vex}"
stack_name="${OS_STACK_NAME}"
stack_template="${OS_STACK_TEMPLATE}"
stack_template_dir="/opt/ciman/${OS_STACK_TEMPLATE_DIR:-openstack-hot}"
stack_parameters="$WORKSPACE/stack-parameters.yaml"

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
    urllib3~=1.26.15 \
    yq

openstack --os-cloud "$os_cloud" limits show --absolute

pushd "$stack_template_dir" || exit 1
lftools-uv openstack --os-cloud "$os_cloud" stack create \
    "$stack_name" "$stack_template" "$stack_parameters"
popd
