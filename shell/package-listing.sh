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

# Capture the CI WORKSPACE safely in the case that it doesn't exist
workspace="${WORKSPACE:-}"

START_PACKAGES=/tmp/packages_start.txt
END_PACKAGES=/tmp/packages_end.txt
DIFF_PACKAGES=/tmp/packages_diff.txt

# Swap to creating END_PACKAGES if we are running in a CI job (determined by if
# we have a workspace env) or if the starting packages listing already exists.
PACKAGES="${START_PACKAGES}"
if ( [ "${workspace}" ] || [ -f "${START_PACKAGES}" ] )
then
    PACKAGES="${END_PACKAGES}"
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

if [ -f "${START_PACKAGES}" ]
then
    diff "${START_PACKAGES}" "${END_PACKAGES}" > "${DIFF_PACKAGES}"
fi

# If running in a Jenkins job, then copy the created files to the archives
# location
if [ "${workspace}" ]
then
    mkdir -p "${workspace}/archives/"
    cp -f /tmp/packages_*.txt "${workspace}/archives/"
fi
