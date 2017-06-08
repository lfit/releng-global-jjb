#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> lftools-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "$WORKSPACE/.virtualenvs/lftools"
# shellcheck source=./.virtualenvs/lftools/bin/activate disable=SC1091
source "$WORKSPACE/.virtualenvs/lftools/bin/activate"
PYTHON="$WORKSPACE/.virtualenvs/lftools/bin/python"
$PYTHON -m pip install --quiet --upgrade pip
$PYTHON -m pip install --quiet --upgrade pipdeptree
$PYTHON -m pip install --quiet --upgrade "lftools<1.0.0"

echo "----> Pip Dependency Tree"
$PYTHON -m pip pipdeptree
