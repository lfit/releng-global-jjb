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
echo "---> pypi-upload.sh"

# Script to publish Python distributions from a folder
# to the PyPI repository in $REPOSITORY which must be a
# key in the .pypirc file

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -x -o pipefail

cd "$WORKSPACE/$TOX_DIR"

virtualenv "/tmp/pypi"
# shellcheck source=/tmp/pypi/bin/activate disable=SC1091
source "/tmp/pypi/bin/activate"

pip install twine
cmd="twine upload -r $REPOSITORY dist/*"
if $DRY_RUN ; then
    echo "INFO: dry-run is set, echoing command only"
    echo $cmd
else
    $cmd
fi
