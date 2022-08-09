#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> update-python-alternatives.sh"
# This script sets the python version on the executor (ubuntu or
# centos/fedora/redhat) distros using {update-}alternatives CLI

PYTHON_ENV_FILE="/tmp/python.env"

update-python-redhat() {
    sudo /usr/sbin/alternatives  --install /usr/bin/python python /usr/bin/python${SET_PYTHON_VERSION} 310
    sudo /usr/sbin/alternatives --set python3 "/usr/bin/python${SET_PYTHON_VERSION}"
    sudo /usr/sbin/alternatives --set python "/usr/bin/python3"
    sudo /usr/sbin/alternatives --display python || true
    echo "$SET_PYTHON_VERSION" > "$PYTHON_ENV_FILE"
}

update-java-ubuntu() {
    HOST_ARCH=$(dpkg --print-architecture)
    sudo /usr/bin/update-alternatives --install /usr/bin/python python /usr/bin/python${SET_PYTHON_VERSION} 310
    sudo /usr/bin/update-alternatives --set python "/usr/bin/python3"
    sudo /usr/bin/update-alternatives --set python3 "/usr/bin/python${SET_PYTHON_VERSION}"
    sudo /usr/bin/update-alternatives --get-selections
    echo "$SET_PYTHON_VERSION" > "$PYTHON_ENV_FILE"
}

if [ ! command -v ${SET_PYTHON_VERSION} >/dev/null 2>&1 ]; then
    echo "ERROR: ${SET_PYTHON_VERSION} is not installed. Upgrade image to newer build";
    exit 1
fi

echo "---> Set Python 3.x version using alternatives CLI"
OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${OS}" in
    fedora|centos|redhat)
        echo "---> RedHat type system detected"
        update-python-redhat
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        update-python-ubuntu
    ;;
esac
python --version
