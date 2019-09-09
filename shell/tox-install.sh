#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail or variables are missing.
set -eu -o pipefail

echo "----> pip install"
# Tox version is pulled in through detox to mitigate version conflict
$PYTHON -m pip install --user --upgrade tox-pyenv

echo "----> pip freeze"
$PYTHON -m pip freeze
