#!/bin/bash -ue
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Don't 'hard-code' the location
cd "$(dirname "$0")"

./package-listing.sh
./basic-settings.sh
./disable-firewall.sh
./create-swap-file.sh

# Entry point for additional local minion customization
# Eg. OpenDaylight has additional bootstrap scripts depending on minion type.
if [ -f "/opt/ciman/jenkins-init-scripts/local-init.sh" ]; then
    /opt/ciman/jenkins-init-scripts/local-init.sh
fi

# Create the jenkins user last so that hopefully we DO NOT have to deal with
# guard files
./create-jenkins-user.sh
