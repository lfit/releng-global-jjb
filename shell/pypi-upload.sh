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
set -eu -o pipefail

echo "INFO: creating virtual environment"
virtualenv -p python3 /tmp/pypi
PATH=/tmp/pypi/bin:$PATH
pipup="python -m pip install -q --upgrade twine"
echo "INFO: $pipup"
$pipup

echo "INFO: cd to tox-dir $TOX_DIR"
cd "$WORKSPACE/$TOX_DIR"

cmd="twine upload -r $REPOSITORY dist/*"
if $DRY_RUN; then
    echo "INFO: dry-run is set, echoing command only"
    echo $cmd
else
    echo "INFO: uploading distributions to repo $REPOSITORY"
    $cmd
    # release job requires this string AND file names
    files=$(ls dist)
    echo "INFO: successfully uploaded distributions $files"
fi

echo "---> pypi-upload.sh ends"
