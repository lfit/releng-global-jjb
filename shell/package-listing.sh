#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
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

OS_FAMILY=$(facter osfamily | tr '[:upper:]' '[:lower:]')

START_PACKAGES=/tmp/packages_start.txt
END_PACKAGES=/tmp/packages_end.txt
DIFF_PACKAGES=/tmp/packages_diff.txt

# This script may be run during system boot, if that is true then there will be
# a starting_packages file. We will want to create a diff if we have a starting
# packages file
PACKAGES="${START_PACKAGES}"
if [ -f "${PACKAGES}" ]
then
    PACKAGES="${END_PACKAGES}"
    CREATEDIFF=1
fi

case "${OS_FAMILY}" in
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

if [ "${CREATEDIFF}" ]
then
    diff "${START_PACKAGES}" "${END_PACKAGES}" > "${DIFF_PACKAGES}"
fi

# If running in a Jenkins job, then copy the created files to the archives
# location
if [ "${WORKSPACE}" ]
then
    mkdir -p "${WORKSPACE}/archives/"
    cp -f /tmp/packages-*.txt "${WORKSPACE}/archives/"
fi
