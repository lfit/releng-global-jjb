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

# This script bumps odlparent

lftools version release PREPARE-RELEASE

# Remove the release tag as it is not needed.
find . -name "*.xml" -print0 | xargs -0 sed -i 's/-PREPARE-RELEASE//g'
