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

cat << EOF > "$REQUIREMENTS_FILE"
lftools~=0.15.0
python-heatclient~=1.16.1
python-openstackclient~=3.16.0
EOF

# Use `python -m pip` to ensure we are using the latest version of pip
python -m pip install --user --quiet --upgrade pip==18.0 setuptools==40.0.0
python -m pip install --user --quiet --upgrade -r "$REQUIREMENTS_FILE"
pip freeze
