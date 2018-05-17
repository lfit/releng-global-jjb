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
echo "---> jjb-cleanup.sh"
# Cleans up the temporary directory created for the virtualenv but only if it
# exists under /tmp. This is to ensure we never attempt to blow away '/'
# through mis-set bash variables.

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

# shellcheck source="$WORKSPACE/.jjb.properties" disable=SC1091
source "$WORKSPACE/.jjb.properties"
if [[ -n "$JJB_VENV" && "$JJB_VENV" =~ /tmp/.* ]]; then
    rm -r "$JJB_VENV" && echo "$JJB_VENV removed"
fi
rm "$WORKSPACE/.jjb.properties"
