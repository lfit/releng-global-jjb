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
echo "---> pypi-dist-build.sh"

# Script to create Python source and binary distributions
# Requires project file "setup.py"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

venv=/tmp/pypi
virtualenv -p python3 $venv
PATH=$venv/bin:$PATH
pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -q -U

bdist=""
if $BUILD_BDIST_WHEEL; then
    echo "INFO: installing wheel to build binary distribution"
    pip install -q wheel
    bdist="bdist_wheel"
fi

echo "INFO: cd to tox-dir $TOX_DIR"
cd "$WORKSPACE/$TOX_DIR"

echo "INFO: creating distributions"
python3 setup.py sdist $bdist

echo "---> pypi-dist-build.sh ends"
