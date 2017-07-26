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


if [ "$GERRIT_BRANCH" == "master" ]; then
    RTD_BUILD_VERSION=latest
else
    RTD_BUILD_VERSION="${{GERRIT_BRANCH/\//-}}"
fi

# shellcheck disable=SC1083
curl -X POST --data "version_slug=$RTD_BUILD_VERSION" https://readthedocs.org/build/{rtdproject}
