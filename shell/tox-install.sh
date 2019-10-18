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
# Use -x to show value of $PYTHON in output
set -eux -o pipefail

#lf env stuff
source ~/lf-env.sh
venv=$(mktemp -d)
python3 -m venv "$venv"
lf-activate "$venv"
pip install --quiet --upgrade pip

if [[ $PYTHON == "python2" ]]; then
    echo "python2 no longer support for tox runs?"
    # Not sure how to deal with project that may need python2 for their tox runs
    exit 1
    #$PYTHON -m pip install --user --quiet --upgrade tox more-itertools~=5.0.0
else
    $PYTHON -m pip install --quiet --upgrade tox
fi
