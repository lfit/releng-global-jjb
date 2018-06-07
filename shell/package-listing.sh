#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

echo "---> package-listing.sh"

# Ensure we fail the job if any steps fail
set -eu -o pipefail

set -x # Trace commands for this script to make debugging easier

OSFAMILY=$(facter osfamily | tr '[:upper:]' '[:lower:]')

STARTPACKAGES=/tmp/starting_packages.txt
ENDPACKAGES=/tmp/ending_packages.txt
DIFFPACKAGES=/tmp/package_diff.txt

# This script may be run during system boot, if that is true than there will be
# no starting_packages file. We will want to create a diff if we have a starting
# packages file
PACKAGES="${STARTPACKAGES}"
if [ -f "${PACKAGES}" ]
then
    PACKAGES="${ENDPACKAGES}"
    CREATEDIFF=1
fi

case "${OSFAMILY}" in
    redhat|suse)
        # RedHat and Suse flavors all use rpm at the package level
        rpm -qa | sort > "${PACKAGES}"
    ;;
    debian)
        # Debian derived flavors all use dpkg at the package level
        dpkg -l | grep '^ii' > "${PACKAGES}"
    ;;
    *)
        # nothing to do
    ;;
esac

# Create a diff if needed
if [ "${CREATEDIFF}" ]
then
    diff "${STARTPACKAGES}" "${ENDPACKAGES}" > "${DIFFPACKAGES}"
fi

# If running in a Jenkins job, then copy the created files to the archives
# location
if [ "${WORKSPACE}" ]
then
    mkdir -p "${WORKSPACE}/archives/"
    # Copy safely, we shouldn't bomb the job if one of these files doesn't exist
    for i in "${STARTPACKAGES}" "${ENDPACKAGES}" "${DIFFPACKAGES}"
    do
        if [ -f "${i}" ]
        then
            cp "${i}" "${WORKSPACE}/archives/${i}"
        fi
    done
fi
