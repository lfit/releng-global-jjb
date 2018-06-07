#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Share script with JJB jobs so we only have to maintain it in one place
JJB_SHELL_DIR="/opt/ciman/jjb/global-jjb/shell"

# Make sure the script is executable and then run it
chmod +x "${JJB_SHELL_DIR}/package-listing.sh"
"${JJB_SHELL_DIR}/package-listing.sh"
