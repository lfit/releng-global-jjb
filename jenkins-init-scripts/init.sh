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

INIT_SCRIPTS_DIR="/opt/ciman/global-jjb/jenkins-init-scripts"

"$INIT_SCRIPTS_DIR/package-listing.sh"
"$INIT_SCRIPTS_DIR/basic-settings.sh"
"$INIT_SCRIPTS_DIR/disable-firewall.sh"
"$INIT_SCRIPTS_DIR/create-swap-file.sh"

# Entry point for additional local minion customization
# Eg. OpenDaylight has additional bootstrap scripts depending on minion type.
if [ -f "/opt/ciman/jenkins-init-scripts/local-init.sh" ]; then
    /opt/ciman/jenkins-init-scripts/local-init.sh
fi

# Create the jenkins user last so that hopefully we DO NOT have to deal with
# guard files
"$INIT_SCRIPTS_DIR/create-jenkins-user.sh"
