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
set -eu -o pipefail
echo "---> Protect in-use images"
os_cloud="${OS_CLOUD:-vex}"

# shellcheck disable=SC1090
source ~/lf-env.sh

# Check if openstack venv was previously created
if [ -f "/tmp/.os_lf_venv" ]; then
    os_lf_venv=$(cat "/tmp/.os_lf_venv")
fi

if [ -d "${os_lf_venv}" ] && [ -f "${os_lf_venv}/bin/openstack" ]; then
    echo "Re-use existing venv: ${os_lf_venv}"
    PATH=$os_lf_venv/bin:$PATH
else
    lf-activate-venv --python python3 \
        python-heatclient \
        python-openstackclient
fi

images=()
while read -r -d $'\n' ; do
    images+=("$REPLY")
done < <(grep -r IMAGE_NAME --include \*.cfg jenkins-config \
            | awk -F'=' '{print $2}' \
            | sort -u)

jjbimages=()
while read -r -d $'\n' ; do
    jjbimages+=("$REPLY")
done < <(grep -r 'ZZCI - ' --include \*.yaml jjb \
            | awk -F": " '{print $3}' \
            | sed -e "s:'::;s:'$::;/^$/d" -e 's/^"//' -e 's/"$//' \
            | sort -u)

if ! [[ ${#images[@]} -eq 0 ]]; then
    echo "INFO: There are images to protect defined in jenkins-config."
else
    echo "ERROR: No images detected in the jenkins-config dir."
    exit 1
fi

if ! [[ ${#jjbimages[@]} -eq 0 ]]; then
    echo "INFO: There are additional images to protect in the jjb dir."
    images=("${images[@]}" "${jjbimages[@]}")
    #dedupe
    readarray -t images < <(printf '%s\n' "${images[@]}" | sort -u)
fi


echo "INFO: Protecting the following images:"
for image in "${images[@]}"; do
    echo "$image"
done

for image in "${images[@]}"; do
    os_image_protected=$(openstack --os-cloud "$os_cloud" \
        image show "$image" -f value -c protected)
    echo "Protected setting for $image: $os_image_protected"

    if [[ $os_image_protected != True ]]; then
        echo "    Image NOT set as protected, changing the protected value."
        openstack --os-cloud "$os_cloud" image set --protected "$image"
    fi
done
