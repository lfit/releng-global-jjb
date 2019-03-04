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

ciman_root=$(readlink -f "$(dirname "$0")"/../..)

echo "    Start init.sh: $SECONDS" >> /time
"$ciman_root/global-jjb/shell/package-listing.sh"
echo "    package-listing.sh: $SECONDS" >> /time
"$ciman_root/global-jjb/jenkins-init-scripts/basic-settings.sh"
echo "    basic-settings.sh: $SECONDS" >> /time
"$ciman_root/global-jjb/jenkins-init-scripts/disable-firewall.sh"
echo "    disable-firewall.sh: $SECONDS" >> /time
"$ciman_root/global-jjb/jenkins-init-scripts/create-swap-file.sh"
echo "    create-swap-file.sh: $SECONDS" >> /time

# Entry point for additional local minion customization
# Note this is called before the 'jenkins' account is created
if [ -e "$ciman_root/jenkins-init-scripts/local-init.sh" ]; then
    "$ciman_root/jenkins-init-scripts/local-init.sh"
fi

# Create the jenkins user last so that hopefully we DO NOT have to deal with
# guard files
"$ciman_root/global-jjb/jenkins-init-scripts/create-jenkins-user.sh"
echo "    create-jenkinis-user.sh: $SECONDS" >> /time
