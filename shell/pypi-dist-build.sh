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
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -x -o pipefail

virtualenv "/tmp/pypi"
# shellcheck source=/tmp/pypi/bin/activate disable=SC1091
source "/tmp/pypi/bin/activate"

bdist=""
if $BUILD_BDIST_WHEEL; then
    pip install wheel
    bdist="bdist_wheel"
fi
python setup.py sdist $bdist
