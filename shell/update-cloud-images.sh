#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Auto-update packer image{s} when the job is started manually or a single
# image passed by upstream packer merge job:
# 1. Get a list of image{s} from the releng/builder repository
# 2. Search openstack cloud for the latest image{s} available or use the image
#    name passed down from the upstream job.
# 3. Compare the time stamps of the new image{s} with the image in use
# 4. Update the image{s} in the config files and yaml files
# 5. Push the change to Gerrit

echo "---> update-cloud-images.sh"

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf_activate_venv python-openstackclient

mkdir -p "$WORKSPACE/archives"
echo "INFO: List of images in use on the source repository:"
grep -Er '(_system_image:|IMAGE_NAME)'                       \
    --exclude-dir="global-jjb" --exclude-dir="common-packer" \
    | grep -oP 'ZZCI\s+.*\d+-\d+\.\d+' | sort -n | uniq      \
    | tee "$WORKSPACE/archives/used_image_list.txt"

while read -r line ; do
    image_in_use="${line}"

    # get image type - ex: builder, docker, gbp etc
    image_type="${line% -*}"
    # Get the latest images available on the cloud, when $NEW_IMAGE_NAME env
    # var is unset and update all images on Jenkins to the latest.
    if [[ $NEW_IMAGE_NAME != all ]]; then
        new_image=${NEW_IMAGE_NAME}
        new_image_type="${NEW_IMAGE_NAME% -*}"
        # get the $new_image_type to check the image type is being compared
        if [[ ${new_image_type} != "${image_type}" ]]; then
            echo "INFO: Image type does not match, continue ..."
            continue
        fi
    else
        new_image=$(openstack image list --long -f value -c Name -c Protected \
            | grep "${image_type}.*False" | tail -n-1 | sed 's/ False//')     \
            || true
    fi
    [[ -z $new_image ]] && continue
    echo "INFO: Found image type match, compare timestamps."

    # strip the timestamp from the image name
    new_image_isotime=${new_image##*- }
    image_in_use_isotime=${image_in_use##*- }
    # Remove '-' & '.' from the timestamp and perform numeric compare
    if [[ ${new_image_isotime//[\-\.]/} -gt ${image_in_use_isotime//[\-\.]/} ]]; then
        # generate a patch to be submited to Gerrit
        echo "INFO: Update old image: $image_in_use with new image: $new_image"
        grep -rlE '(_system_image:|IMAGE_NAME)' \
            | xargs sed -i "s/${image_in_use}/${new_image}/"
        # When the script is triggered by upstream packer-merge job
        # update only the requested image and break the loop
        [[ $NEW_IMAGE_NAME != all ]] && break
    else
        echo "INFO: No new image to update: $new_image"
    fi
done < "$WORKSPACE/archives/used_image_list.txt"

git diff > "$WORKSPACE/archives/new-images-patchset.diff"
git add -u
git status
