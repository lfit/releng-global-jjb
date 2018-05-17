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
echo "---> jjb-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

VENV_DIR="$(mktemp -d)"
virtualenv "$VENV_DIR"
# shellcheck source=$VENV_DIR/bin/activate disable=SC1091
source "$VENV_DIR/bin/activate"
pip install --quiet --upgrade "pip==9.0.3" setuptools
pip install --quiet --upgrade "jenkins-job-builder==$JJB_VERSION"

echo "----> pip freeze"
pip freeze
