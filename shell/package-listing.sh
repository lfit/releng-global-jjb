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

# Stop at the first error, but never change the build result. This script
# only collects a package listing for the archive, so a failure here says
# nothing about the job under test.
set -eu -o pipefail
trap 'exit 0' EXIT

set -x # Trace commands for this script to make debugging easier

# Detect the OS family using /etc/os-release (works on all modern distros)
# Falls back to facter for legacy images that still have it installed
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case " ${ID:-} ${ID_LIKE:-} " in
        *" debian "*) OS_FAMILY="debian" ;;
        *" rhel "* | *" fedora "*) OS_FAMILY="redhat" ;;
        *" suse "*) OS_FAMILY="suse" ;;
        *) OS_FAMILY="${ID:-}" ;;
    esac
elif command -v facter > /dev/null 2>&1; then
    OS_FAMILY=$(facter osfamily | tr '[:upper:]' '[:lower:]')
else
    echo "ERROR: Unable to detect OS: /etc/os-release not found and facter not installed"
    exit 1
fi

# Capture the CI WORKSPACE safely in the case that it doesn't exist
workspace="${WORKSPACE:-}"

START_PACKAGES=/tmp/packages_start.txt
END_PACKAGES=/tmp/packages_end.txt
DIFF_PACKAGES=/tmp/packages_diff.txt

# Swap to creating END_PACKAGES if we are running in a CI job (determined by if
# we have a workspace env) or if the starting packages listing already exists.
PACKAGES="${START_PACKAGES}"
if [ "${workspace}" ] || [ -f "${START_PACKAGES}" ]; then
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

if [ -f "${START_PACKAGES}" ] && [ -f "${END_PACKAGES}" ]; then
    # ` || true` Ignore exit code because diff exits 1 when there is a diff
    diff "${START_PACKAGES}" "${END_PACKAGES}" > "${DIFF_PACKAGES}" || true
fi

# If running in a Jenkins job, then copy the created files to the archives
# location
if [ "${workspace}" ]; then
    mkdir -p "${workspace}/archives/"
    cp -f /tmp/packages_*.txt "${workspace}/archives/"
fi
