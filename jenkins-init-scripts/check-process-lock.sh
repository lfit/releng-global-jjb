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

OS=$(facter operatingsystem)

case "$OS" in
    Ubuntu)
        # Check for apt lock file and wait for any background processes to finish
        echo "alias apt='while [ \$(fuser \"/var/lib/dpkg/lock\") ]; do echo \"Waiting on apt lock...\"; sleep 1; done; sudo apt \"\$@\"'" > ~/.bashrc
    ;;
    *)
        # nothing to do
    ;;
esac

# vim: ts=4 ts=4 sts=4 et :
