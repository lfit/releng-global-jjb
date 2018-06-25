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
        # Wait for any background processes to finish
        while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
    ;;
    *)
        # nothing to do
    ;;
esac

# vim: ts=4 ts=4 sts=4 et :
