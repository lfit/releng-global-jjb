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
echo "---> sudo-logs.sh"

# Stop at the first error, but never change the build result. This script
# only collects sudo logs for the archive, so a failure here says nothing
# about the job under test.
set -eu -o pipefail -o noglob
trap 'exit 0' EXIT

# Copy/Generate 'sudo' log and copy to archive directory
copy_log () {
    case $os in
        fedora|centos|redhat|ubuntu|debian)
            if ! sudo cp "$sudo_log" /tmp; then
                echo "Unable to archive 'sudo' logs ($sudo_log)"
                return
            fi
            ;;
        suse)
            # Do I need 'sudo' to run 'journalctl'?
            journalctl | grep sudo > "$sudo_log"
            ;;
        *)  echo "Unexpected 'operatingsystem': $os"
            exit 1
            ;;
    esac
    sudo_log=$(basename "$sudo_log")
    sudo chown "$(id -nu)": "/tmp/$sudo_log"
    chmod 0644 "/tmp/$sudo_log"
    mkdir -p "$WORKSPACE/archives/sudo"
    mv "/tmp/$sudo_log" "$WORKSPACE/archives/sudo/$sudo_log"

}    # End copy_log()

echo "Archiving 'sudo' log.."
# Detect the OS using /etc/os-release (works on all modern distros)
# Falls back to facter for legacy images that still have it installed
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os="${ID:-}"
    # facter spelled RHEL "redhat", keep that spelling for the cases below
    if [ "$os" = "rhel" ]; then
        os="redhat"
    fi
elif command -v facter > /dev/null 2>&1; then
    os=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
else
    echo "ERROR: Unable to detect OS: /etc/os-release not found and facter not installed"
    exit 1
fi
case $os in
    fedora|centos|redhat) sudo_log=/var/log/secure   ;;
    ubuntu|debian)        sudo_log=/var/log/auth.log ;;
    suse)                 sudo_log=/tmp/sudo.log     ;;
    *)  echo "Unexpected 'operatingsystem': $os"
        exit 1
        ;;
esac

copy_log
