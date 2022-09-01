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
# Removes openstack images older than X days in the cloud
echo "---> Cleanup old images"

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "cryptography<3.4" \
    "lftools[openstack]" \
    kubernetes \
    "niet~=1.4.2" \
    python-heatclient \
    python-openstackclient \
    python-magnumclient \
    setuptools \
    "openstacksdk<0.99" \
    yq

os_cloud="${OS_CLOUD:-vex}"
os_image_cleanup_age="${OS_IMAGE_CLEANUP_AGE:-30}"

set -eux -o pipefail

lftools openstack --os-cloud "${os_cloud}" image cleanup --days="${os_image_cleanup_age}"
