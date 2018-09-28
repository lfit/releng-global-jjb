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

OS=$(ANSIBLE_STDOUT_CALLBACK=json ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ansible
    \ localhost -m setup | jq -r \
    '.plays[0].tasks[0].hosts.localhost.ansible_facts.ansible_distribution' \
    | tr '[:upper:]' '[:lower:]')

case "$OS" in
    fedora)
        systemctl stop firewalld
    ;;
    centos|redhat)
        if [ "$(ANSIBLE_STDOUT_CALLBACK=json ANSIBLE_LOAD_CALLBACK_PLUGINS=1 \
            ansible localhost -m setup | jq -r \
            '.plays[0].tasks[0].hosts.localhost.ansible_facts.distrubtion_major_version')" \
            -lt "7" ]; then
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
