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

OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

useradd -m -s /bin/bash jenkins

if grep -q docker /etc/group; then
    usermod -a -G docker jenkins
fi

# Used for building RPMs
if grep -q mock /etc/group; then
    usermod -a -G mock jenkins
fi

mkdir /home/jenkins/.ssh /w
cp -r "/home/${OS}/.ssh/authorized_keys" /home/jenkins/.ssh/authorized_keys

# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w
chmod 700 /home/jenkins/.ssh
