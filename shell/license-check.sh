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
echo "---> license-check.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

if hash lhc 2>/dev/null; then
    echo "License Header Checker is installed."
    lhc --version
else
    echo "License Header Checker is not installed. Installing..."
    mkdir "$WORKSPACE/bin"
    # TODO: Update this once we have a more permanent location for the project.
    wget -nv -O "$WORKSPACE/bin/lhc" https://github.com/zxiiro/license-header-checker/releases/download/v0.1.0/lhc
    chmod +x "$WORKSPACE/bin/lhc"
    export PATH="$WORKSPACE/bin:$PATH"
    lhc --version
fi

lhc --license Apache-2.0,EPL-1.0,MIT \
    --exclude "$LICENSE_EXCLUDE_PATHS" \
    '*.go' \
    '*.java' \
    '*.py' \
    '*.sh'
