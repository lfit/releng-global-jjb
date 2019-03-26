#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

set -eux -o pipefail

REQUIREMENTS_FILE=$(mktemp /tmp/requirements-XXXX.txt)

# Note: To test lftools master branch change the lftools configuration below in
#       the requirements file from "lftools[openstack]~=#.##.#" to
#       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

cat << EOF > "$REQUIREMENTS_FILE"
lftools[openstack]~=0.22.1
python-heatclient~=1.16.1
python-openstackclient~=3.16.0
dogpile.cache~=0.6.8  # Version 0.7.[01] seems to break openstackclient
niet~=1.4.2 # Extract values from yaml
EOF

echo "Requirements file"
echo "-----------------"
cat "$REQUIREMENTS_FILE"

# Use `python -m pip` to ensure we are using the latest version of pip
python -m pip install --user --quiet --upgrade pip
python -m pip install --user --quiet --upgrade setuptools
python -m pip install --user --quiet --upgrade -r "$REQUIREMENTS_FILE"
pip freeze
