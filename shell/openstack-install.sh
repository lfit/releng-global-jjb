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
# Install the openstack cli
echo "---> Install openstack cli"

set -eux -o pipefail

pip install --user --quiet --upgrade "pip<10.0.0" setuptools
pip install --user --quiet --upgrade python-openstackclient python-heatclient
pip freeze
