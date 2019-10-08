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
echo "---> utility-venv.sh"

# Script to create a venv for our utilities
# Can be used for builds that do not have specific versions set in
# requirements.txt

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

venv=/tmp/pypi
virtualenv -p python3 $venv
PATH=$venv/bin:$PATH

# Upgrade any outdated packages via pip
pip install $(pip list --outdated | awk '{ print $1 }') --upgrade

echo "INFO: installing venv utilities"
pip install jsonschema \
    lftools \
    niet \
    python-heatclient \
    python-openstackclient \
    tox \
    tox-pyenv \
    twine \
    yq

echo "---> utility-venv.sh ends"
