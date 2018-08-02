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
# Checks the image "protected" value and set "True" marker
#
# The script searches the ciman repo for the images presently used and ensures
# the protection setting is set for those images to prevent the image from
# getting purged by the image cleanup script.
# This script assumes images prefixed with the string "ZZCI - " are ci-managed
# images.
echo "---> Protect in-use images"

os_cloud="${OS_CLOUD:-vex}"

set -eu -o pipefail

declare -a yaml_images
readarray -t yaml_images <<< "$(grep -r 'ZZCI - ' --include \*.yaml \
    | awk -F": " -e '{print $3}' | sed "s:'::;s:'$::;/^$/d" | sort -u)"
declare -a cfg_images
readarray -t cfg_images <<< "$(grep -r IMAGE_NAME --include \*.cfg \
    | awk -F'=' -e '{print $2}' | sort -u)"
combined=("${yaml_images[@]}" "${cfg_images[@]}")
declare -a images
readarray -t images <<< "$(printf '%s\n' "${combined[@]}" | sort -u)"

for image in "${images[@]}"; do
    os_image_protected=$(openstack --os-cloud "$os_cloud" \
        image show "$image" -f value -c protected)
    echo "Protected setting for $image: $os_image_protected"

    if [[ $os_image_protected != True ]]; then
        echo "    Image NOT set as protected, changing the protected value."
        openstack --os-cloud "$os_cloud" image set --protected "$image"
    fi
done
