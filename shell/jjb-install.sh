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
echo "---> jjb-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

# Create a virtualenv in a temporary directoy and write it down to used
# or cleaned up later; cleanup is done in the script jjb-cleanup.sh.
JJB_VENV="$(mktemp -d)"
export JJB_VENV
virtualenv "$JJB_VENV"
echo "JJB_VENV=$JJB_VENV" > "$WORKSPACE/.jjb.properties"
# shellcheck source=$VENV_DIR/bin/activate disable=SC1091
source "$JJB_VENV/bin/activate"
python -m pip install --quiet --upgrade "jenkins-job-builder==$JJB_VERSION"

echo "----> pip freeze"
pip freeze
