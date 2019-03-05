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

conf_images=("$(grep -r IMAGE_NAME --include \*.cfg jenkins-config \
               | awk -F'=' '{print $2}' | sort -u)")
# If there are no yaml files the 'grep' will fail, which is OK
yaml_images=("$(grep -r 'ZZCI - ' --include \*.yaml jjb \
               | awk -F": " '{print $3}' | sed "s:'::;s:'$::;/^$/d" \
               | sort -u)") || true
readarray -t images <<< "$(for i in "${conf_images[@}" "${yaml_images[@]}"; do \
                           echo "$i"; done | sort)"

for image in "${images[@]}"; do
    [[ -z $image ]] && continue
    os_image_protected=$(openstack --os-cloud "$os_cloud" \
        image show "$image" -f value -c protected)
    echo "Protected setting for $image: $os_image_protected"

    if [[ $os_image_protected != True ]]; then
        echo "    Image NOT set as protected, changing the protected value."
        openstack --os-cloud "$os_cloud" image set --protected "$image"
    fi
done
