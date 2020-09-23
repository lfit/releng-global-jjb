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

images=()
while read -r -d $'\n' ; do
  images+=("$REPLY")
done < <(grep -r IMAGE_NAME --include \*.cfg jenkins-config | awk -F'=' '{print $2}' | sort -u)

jjbimages=()
while read -r -d $'\n' ; do
  jjbimages+=("$REPLY")
done < <(grep -r 'ZZCI - ' --include \*.yaml jjb |  awk -F": " '{print $3}' | sed -e "s:'::;s:'$::;/^$/d" -e 's/^"//' -e 's/"$//' | sort -u)

if ! [[ ${#images[@]} -eq 0 ]]; then
  echo "INFO: There are images to protect defined in jenkins-config."
else
  echo "ERROR: No images detected in the jenkins-config dir."
  exit 1
fi

if ! [[ ${#jjbimages[@]} -eq 0 ]]; then
  echo "INFO: There are additional images to protect in the jjb dir."
  images=("${images[@]}" "${jjbimages[@]}")
fi

echo "INFO: Protecting the following images:"
for image in "${images[@]}"; do
  echo "$image"
done

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
