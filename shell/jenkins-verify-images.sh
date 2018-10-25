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

error=false

for file in jenkins-config/clouds/openstack/*/*; do
  # Set the $IMAGE_NAME variable to the the file's IMAGE_NAME value
  export "$(grep IMAGE_NAME $file)"
  # The image should be listed as active
  openstack image list --property name="$IMAGE_NAME" | grep "active"
  if [ $? -ne 0 ]; then
    echo "ERROR: No matching image found for $IMAGE_NAME"
    error=true
  fi
done

if [ "$error" = true ]; then
  exit 1
fi
