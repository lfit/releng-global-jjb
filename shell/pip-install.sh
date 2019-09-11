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
# pip install packages into a virtualen
#
# PIP_PACKAGES is a space separated list of pypi packages to install.
echo "---> pip-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

python -m venv /tmp/v/venv/
# shellcheck disable=SC1091
source /tmp/v/venv/bin/activate
python -m pip install --quiet --upgrade pipdeptree setuptools
# PIP_PACKAGES needs to be passed through as a space separated list of packages
# shellcheck disable=SC2086
python -m pip install --upgrade $PIP_PACKAGES

echo "----> Pip Dependency Tree"
pipdeptree
