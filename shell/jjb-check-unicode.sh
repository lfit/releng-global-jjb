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
echo "---> jjb-check-unicode.sh"

if LC_ALL=C grep -I -r '[^[:print:][:space:]]' jjb/; then
    echo "Found files containing non-ascii characters."
    exit 1
fi

echo "All files are ASCII only"
