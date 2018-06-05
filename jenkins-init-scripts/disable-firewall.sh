#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2015 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

OS=$(facter operatingsystem)

case "$OS" in
    Fedora)
        systemctl stop firewalld
    ;;
    CentOS|RedHat)
        if [ "$(facter operatingsystemrelease | cut -d '.' -f1)" -lt "7" ]; then
            service iptables stop
        else
            systemctl stop firewalld
        fi
    ;;
    *)
        # nothing to do
    ;;
esac

# vim: ts=4 ts=4 sts=4 et :
