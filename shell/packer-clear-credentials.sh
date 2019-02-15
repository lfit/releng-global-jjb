#!/bin/bash -ue
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> packer-clear-credentials.sh"

# OK if $CLOUDENV does not exist or empty
# Fails if $CLOUDENV exists and rm is unable to delete it
rm -rf "$CLOUDENV"
