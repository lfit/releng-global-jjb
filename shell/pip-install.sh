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
# pip install packages into a virtualenv using the first listed package as venv name
#
# PIP_PACKAGES is a space separated list of pypi packages to install. The first
#              listed package is used as the virtualenv directory name.
echo "---> pip-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

# Install git-review using virtualenv to the latest version that supports
# --reviewers option, available through pip install. Existing minion image has a
# version that does not have it.
virtualenv "/tmp/v/${PIP_PACKAGES%% *}"
# shellcheck source=/tmp/v/venv/bin/activate disable=SC1091
source "/tmp/v/${PIP_PACKAGES%% *}/bin/activate"
pip install --quiet --upgrade "pip==9.0.3" setuptools
pip install --quiet --upgrade pipdeptree

# PIP_PACKAGES needs to be passed through as a space separated list of packages
# shellcheck disable=SC2086
pip install --upgrade $PIP_PACKAGES

echo "----> Pip Dependency Tree"
pipdeptree
