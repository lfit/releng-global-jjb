#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2015 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Detect the OS using /etc/os-release (works on all modern distros)
# Falls back to facter for legacy images that still have it installed
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="${ID:-}"
    # facter spelled RHEL "redhat", keep that spelling for the cases below
    if [ "$OS" = "rhel" ]; then
        OS="redhat"
    fi
    os_release_ver=$(echo "${VERSION_ID:-0}" | cut -d '.' -f1)
elif command -v facter > /dev/null 2>&1; then
    OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
    os_release_ver="$(facter operatingsystemrelease | cut -d '.' -f1)"
else
    echo "ERROR: Unable to detect OS: /etc/os-release not found and facter not installed"
    exit 1
fi

case "$OS" in
    fedora)
        systemctl stop firewalld
    ;;
    centos|redhat)
        if [ "${os_release_ver}" -lt "7" ]; then
            service iptables stop
        else
            systemctl stop firewalld
        fi
    ;;
    *)
        # nothing to do
    ;;
esac

# vim: ts=4 ts=4 sts=4 et :
