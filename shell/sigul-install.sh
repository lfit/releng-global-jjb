#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> sigul-install.sh"

# Ensure we fail the job if any steps fail.
set -e -o pipefail

# Setup sigul RPM repo
echo "[fedora-infra-sigul]
name=Fedora builder packages for sigul
baseurl=https://infrastructure.fedoraproject.org/repo/\$releasever/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://infrastructure.fedoraproject.org/repo/infra/RPM-GPG-KEY-INFRA-TAGS
includepkgs=sigul*
skip_if_unavailable=True" > fedora-infra-sigul.repo

sudo cp fedora-infra-sigul.repo /etc/yum.repos.d
rm fedora-infra-sigul.repo

# install sigul
sudo yum install -y -q sigul

# configure /etc/hosts with the sigul bridge hostname
# This is needed as build minions can't always get DNS resolution
# on the bridge
BRIDGE_HOST=$(grep bridge-hostname "$SIGUL_CONFIG" | awk '{print $2}')

# SIGUL_BRIDGE_IP must be defined as a Jenkins env variable
cp /etc/hosts hosts
echo -e "$SIGUL_BRIDGE_IP\t$BRIDGE_HOST" >> hosts
sudo cp hosts /etc/hosts
rm hosts
