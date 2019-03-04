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

# DEBUG
exec  > /create-swap-files.log 2>&1
set -x
# Get the blockCount from the 'SWAP_SIZE' environmental variable
blockCount=${SWAP_SIZE-''}

# Validate SWAP_SIZE
# Empty:   Set blockCount 1
# Zero:    No Swap
# Integer: Set blockCount
# Else:    No Swap
case $blockCount in
    '')      blockCount=1 ;;
    [0-9]*)  blockCount=$blockCount ;;
    *)       exit ;;
esac
[[ $blockCount == 0 ]] && exit

time dd if=/dev/zero of=/swap count="${blockCount}k" bs=1MiB
chmod 600 /swap
mkswap /swap
swapon /swap
