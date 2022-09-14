#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> jenkins-verify-images.sh"
# Verifies that openstack contains an image for each config file defined in the
# jenkins-config/clouds/openstack directory.

set -eux -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

if [ -f "/tmp/.os_lf_venv" ]; then
    os_lf_venv=$(cat "/tmp/.os_lf_venv")
fi

if [ -d "${os_lf_venv}" ] && [ -f "${os_lf_venv}/bin/openstack" ]; then
    echo "Re-use existing venv: ${os_lf_venv}"
    PATH=$os_lf_venv/bin:$PATH
else
    lf_activate_venv --python python3 python-openstackclient
fi
error=false

verify_images()
{
    echo "Verifying images on $1"
    for file in "$1"/*; do
        # Set the $IMAGE_NAME variable to the the file's IMAGE_NAME value
        export "$(grep ^IMAGE_NAME= "$file")"
        # The image should be listed as active

        if ! openstack image list --property name="$IMAGE_NAME" | grep "active"; then
            echo "ERROR: No matching image found for $IMAGE_NAME"
            error=true
        fi
        # Set the $HARDWARE_ID variable to the the file's HARDWARE_ID value
        export "$(grep ^HARDWARE_ID= "$file")"
        # The flavor should be listed. Spaces in grep string ensure complete match.

        if ! openstack flavor list | grep " $HARDWARE_ID "; then
            echo "ERROR: No matching flavor found for $HARDWARE_ID"
            error=true
        fi
    done
}

echo "Verifying that cloud has a master configuration file"
if [[ -d jenkins-config/clouds/openstack ]]; then
    for cloud in jenkins-config/clouds/openstack/*; do
        if [[ -f $cloud/cloud.cfg ]]; then
            # Get the OS_CLOUD variable from cloud config
            if ! os_cloud=$(grep -E "^OS_CLOUD=" "$cloud/cloud.cfg" | cut -d'=' -f2); then
            os_cloud="vex"
            fi
            OS_CLOUD=$os_cloud verify_images "$cloud"
        else
            echo "ERROR: No cloud.cfg for $cloud"
            error=true
        fi
    done
fi

if $error; then
    exit 1
fi
