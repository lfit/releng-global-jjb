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
echo "---> jjb-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv "$WORKSPACE/.virtualenvs/jjb"
# shellcheck disable=SC1073,SC1091 source=./.virtualenvs/jjb/bin/activate
source "$WORKSPACE/.virtualenvs/jjb/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade pipdeptree
pip install --quiet --upgrade "jenkins-job-builder==$JJB_VERSION"

echo "----> Pip Dependency Tree"
pipdeptree
