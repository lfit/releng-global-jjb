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
echo "---> sysstat.sh"
set +e  # DON'T fail build if script fails.

if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
    exit 0
fi


# Detect the OS using /etc/os-release (works on all modern distros)
# Falls back to facter for legacy images that still have it installed
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="${ID:-}"
    os_release="${VERSION_ID:-}"
    # facter spelled RHEL "redhat", keep that spelling for the cases below
    if [ "$OS" = "rhel" ]; then
        OS="redhat"
    fi
elif command -v facter > /dev/null 2>&1; then
    OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
    os_release=$(facter operatingsystemrelease)
else
    # DON'T fail build if the OS cannot be determined.
    echo "WARN: Unable to detect OS, skipping sar report collection"
    exit 0
fi

case "$OS" in
    ubuntu)
        case $os_release in
            18.04|20.04|22.04|24.04|25.04)
                if ! systemctl status sysstat > /dev/null; then
                    exit 0
                fi
                ;;
            *)
                echo "WARN: Unknown Release: Ubuntu $os_release"
                exit 0
                ;;
        esac
        SYSSTAT_PATH="/var/log/sysstat"
    ;;
    centos|redhat)
        SYSSTAT_PATH="/var/log/sa"
    ;;
    *)
        # nothing to do
        exit 0
    ;;
esac

SAR_DIR="$WORKSPACE/archives/sar-reports"
mkdir -p "$SAR_DIR"
cp "$SYSSTAT_PATH/"* "$SAR_DIR"
# convert sar data to ascii format
while IFS="" read -r sarfilenum; do
    [ -f "$sarfilenum" ] && LC_TIME=POSIX sar -A -f "$sarfilenum" > "$SAR_DIR/sar${sarfilenum//[!0-9]/}"
done < <(find "$SYSSTAT_PATH" -name "sa[0-9]*" || true)

# DON'T fail build if script fails.
exit 0
