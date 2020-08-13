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

declare -a images
images+=("$(grep -r IMAGE_NAME --include \*.cfg jenkins-config \
    | awk -F'=' '{print $2}' | sort -u)")
set +o pipefail  # Not all projects have images in YAML files and grep returns non-zero on 0 results
# Ignore SC2179 since we do not want () to result in an empty array item.
#shellcheck disable=SC2179
images+=("$(grep -r 'ZZCI - ' --include \*.yaml jjb \
    | awk -F": " '{print $3}' | sed -e "s:'::;s:'$::;/^$/d" -e 's/^"//' -e 's/"$//' | sort -u)")
set -o pipefail
readarray -t images <<< "$(for i in "${images[@]}"; do echo "$i"; done | sort -u)"

for image in "${images[@]}"; do
    os_image_protected=$(openstack --os-cloud "$os_cloud" \
        image show "$image" -f value -c protected)
    echo "Protected setting for $image: $os_image_protected"

    if [[ $os_image_protected != True ]]; then
        echo "    Image NOT set as protected, changing the protected value."
        openstack --os-cloud "$os_cloud" image set --protected "$image"
    fi
done
