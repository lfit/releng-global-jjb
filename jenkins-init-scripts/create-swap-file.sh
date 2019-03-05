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

# Get the number of blocks from the 'SWAP_COUNT' environmental variable
swapCount=${SWAP_COUNT-1k}

[[ $swapCount == 0 ]] && exit

dd if=/dev/zero of=/swap count="$swapCount" bs=1MiB
chmod 600 /swap
mkswap /swap
swapon /swap
