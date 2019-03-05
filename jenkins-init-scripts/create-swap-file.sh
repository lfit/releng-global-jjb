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

# Get the blockCount from the 'SWAP_COUNT' environmental variable
swapCount=${SWAP_COUNT-''}

# Validate SWAP_COUNT
# Empty:   Set blockCount 1
# Zero:    No Swap
# Integer: Set blockCount
# Else:    No Swap
case $swapCount in
    '')      blockCount=1 ;;
    [0-9]*)  blockCount=$swapCount ;;
    *)       exit ;;
esac
[[ $blockCount == 0 ]] && exit

echo "Allocating ${blockCount}GB of Swap"

dd if=/dev/zero of=/swap count="${swapCount}k" bs=1MiB
chmod 600 /swap
mkswap /swap
swapon /swap
