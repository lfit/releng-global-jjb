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

ciman_init_scripts=$(readlink -f "$(dirname "$0")"/../../jenkins-init-scripts)
jjb_init_scripts=$(readlink -f "$(dirname "$0")")

"$jjb_init_scripts/package-listing.sh"
"$jjb_init_scripts/basic-settings.sh"
"$jjb_init_scripts/disable-firewall.sh"
"$jjb_init_scripts/create-swap-file.sh"

# Entry point for additional local minion customization
# Note this is called before the 'jenkins' account is created
if [ -e "$ciman_init_scripts/local-init.sh" ]; then
    "$ciman_init_scripts/local-init.sh"
fi

# Create the jenkins user last so that hopefully we DO NOT have to deal with
# guard files
"$jjb_init_scripts/create-jenkins-user.sh"
