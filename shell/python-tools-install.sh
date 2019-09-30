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

set -eu -o pipefail

# We are depricatting using a user venv, but for now there are many 
# dependencies on it
if [[ ! -d ~/.local ]]; then
    requirements_file=$(mktemp /tmp/requirements-XXXX.txt)

    # Note: To test lftools master branch change the lftools configuration below in
    #       the requirements file from "lftools[openstack]~=#.##.#" to
    #       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

    echo "Generating Requirements File"
    cat << 'EOF' > "$requirements_file"
lftools[openstack]
python-heatclient
python-openstackclient
niet~=1.4.2
tox>=3.7.0 # Tox 3.7 or greater is necessary for parallel mode support
yq
EOF

    # Use `python -m pip` to ensure we are using the latest version of pip
    (
    PATH=$PATH:~/.local/bin
    python3 -m venv ~/.local
    python3 -m pip install --user --quiet --upgrade pip
    python3 -m pip install --user --quiet --upgrade setuptools
    python3 -m pip install --user --quiet --upgrade -r "$requirements_file"
    )
    rm -rf "$requirements_file"
fi

