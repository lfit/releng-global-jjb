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
echo "---> sigul-install.sh"

# Ensure we fail the job if any steps fail.
set -e -o pipefail

# Detect the OS using /etc/os-release (works on all modern distros)
# Falls back to facter for legacy images that still have it installed
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="${ID:-}"
    # facter spelled RHEL "redhat", keep that spelling for the check below
    if [ "$OS" = "rhel" ]; then
        OS="redhat"
    fi
elif command -v facter > /dev/null 2>&1; then
    OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
else
    echo "ERROR: Unable to detect OS: /etc/os-release not found and facter not installed"
    exit 1
fi

if ! [[ "${OS}" =~ ^(fedora|centos|redhat) ]]; then
    echo "INFO: Skip step, sigul install not available on platform ${OS}"
    exit 0
fi

if command -v sigul &>/dev/null; then
    echo "Sigul already installed; skipping installation."
else
    # Setup sigul RPM repo
    echo "[fedora-infra-sigul]
name=Fedora builder packages for sigul
baseurl=https://kojipkgs.fedoraproject.org/repos-dist/epel\$releasever-infra/latest/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://infrastructure.fedoraproject.org/repo/infra/RPM-GPG-KEY-INFRA-TAGS
includepkgs=sigul*
skip_if_unavailable=True" > fedora-infra-sigul.repo

    sudo cp fedora-infra-sigul.repo /etc/yum.repos.d
    rm fedora-infra-sigul.repo

    # install sigul
    sudo yum install -y -q sigul
fi;
