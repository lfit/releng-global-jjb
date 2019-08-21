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
echo "---> pypi-publish.sh"

# Script to publish Python distributions from a folder
# to the PyPI defined in environment variable

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -x -o pipefail

virtualenv /tmp/v/twine
source "/tmp/v/twine/bin/activate"
pip install twine
twine upload -r $PYPI_SERVER dist/*
