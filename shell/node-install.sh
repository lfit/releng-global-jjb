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
echo "---> node-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "/tmp/v/python"
# shellcheck source=/tmp/v/node/bin/activate disable=SC1091
source "/tmp/v/python/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade pipdeptree
pip install --quiet --upgrade nodeenv

echo "----> Pip Dependency Tree"
pipdeptree
