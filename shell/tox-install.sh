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

# Tox version is pulled in through detox to mitigate version conflict


if [[ $PYTHON == "python2" ]]; then
    $PYTHON -m pip install --quiet --upgrade tox tox-pyenv virtualenv more-itertools~=5.0.0
else
    $PYTHON -m pip install --quiet --upgrade tox tox-pyenv virtualenv
fi


$PYTHON -m pip freeze
