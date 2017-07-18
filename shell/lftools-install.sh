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
echo "---> lftools-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "/tmp/v/lftools"
# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade "lftools<1.0.0"

# pipdeptree prints out a lot of information because lftools pulls in many
# dependencies. Let's only print it if we want to debug.
# echo "----> Pip Dependency Tree"
# pip install --quiet --upgrade pipdeptree
# pipdeptree
