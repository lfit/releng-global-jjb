#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# The 'init' scripts are located in 'jenkins-init-scripts' directory.
# The 'global-jjb' scripts are located in 'shell' directory.  The
# 'package-listing' script is used by both, this is a simple wrapper
# for 'shell/package-listing.sh'. Arguments would be quietly discarded.

jjb_root="$(dirname "$0")/.."

"$jjb_root/shell/package-listing.sh"
