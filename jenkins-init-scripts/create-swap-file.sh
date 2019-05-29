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

# Get the swap_size from the 'SWAP_SIZE' environmental variable
swap_size=${SWAP_SIZE-''}

# Validate SWAP_SIZE
# Empty:   Set swap_size 1
# Zero:    No Swap
# Integer: Set swap_size
# Else:    No Swap
case $swap_size in
    '')      swap_size=1 ;;
    [0-9]*)  swap_size=$swap_size ;;
    *)       exit ;;
esac
[[ $swap_size == 0 ]] && exit

echo "Allocating ${swap_size}GB Swapspace"
rm -rf /swap
touch /swap     # fallocate expects file to exist
fallocate --zero-range --length "${swap_size}GiB" /swap
chmod 600 /swap
mkswap /swap
swapon /swap
