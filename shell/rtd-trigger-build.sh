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
# Call cURL to trigger a build in RTD via the Generic API
#
# Paramters:
#     RTD_BUILD_URL: The unique build URL for the project.
#                    Check Admin > Integrations > Generic API incoming webhook.
#
#     RTD_TOKEN: The unique token for the project Generic webhook.
#                Check Admin > Integrations > Generic API incoming webhook.

echo "---> rtd-trigger-build.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u
set -xe -o pipefail

curl -X POST -d "branches=${GERRIT_BRANCH}" -d "token=$RTD_TOKEN" "$RTD_BUILD_URL"
