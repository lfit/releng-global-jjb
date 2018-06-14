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
echo "---> lftools-activate.sh"

# This script activates the virtualenv containing lftools so it can be
# used by other scripts included in the same build step.
# shellcheck source=$WORKSPACE/.lftools.properties disable=SC1091
source "$WORKSPACE/.lftools.properties"
# shellcheck source=$LFTOOLS_VENV/bin/activate disable=SC1091
source "$LFTOOLS_VENV/bin/activate"
