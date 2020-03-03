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
echo "---> python-tools-install.sh"

set -eufo pipefail

# This script will typically be called during pre-build & post-build.
# Create the user venv during pre-build.
if [[ ! -f /tmp/pre-build-complete ]]; then
    requirements_file=$(mktemp /tmp/requirements-XXXX.txt)

    # Note: To test lftools master branch change the lftools configuration below in
    #       the requirements file from "lftools[openstack]~=#.##.#" to
    #       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

    echo "Generating Requirements File"
    cat << 'EOF' > "$requirements_file"
lftools[openstack]==0.30.1
python-heatclient
python-openstackclient
python-magnumclient
kubernetes
niet~=1.4.2
tox>=3.7.0 # Tox 3.7 or greater is necessary for parallel mode support
yq
EOF

    # Use `python -m pip` to upgrade to the latest pip into user site-packages
    python3 -m pip install --user --quiet --upgrade pip
    python3 -m pip install --user --quiet --no-warn-script-location --upgrade setuptools
    python3 -m pip install --user --quiet --no-warn-script-location --upgrade --upgrade-strategy eager -r "$requirements_file"
    # installs are silent, show version details in log
    python3 --version
    python3 -m pip --version
    python3 -m pip freeze
    rm -rf "$requirements_file"
    touch /tmp/pre-build-complete
fi
