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
echo "---> rtd-trigger-build.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -xe -o pipefail

if [ "$GERRIT_BRANCH" == "master" ]; then
    RTD_BUILD_VERSION=latest
else
    RTD_BUILD_VERSION="${GERRIT_BRANCH/\//-}"
fi

curl -X POST --data "version_slug=$RTD_BUILD_VERSION" "https://readthedocs.org/build/$RTD_PROJECT"
