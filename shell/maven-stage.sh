#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This script publishes artifacts to a staging repo in Nexus.
#
# This script expects the directory $WORKSPACE/m2repo to exist and uses that to
# deploy the staging repository.
#
# This script expects the $NEXUS_URL Jenkins global variable to exist.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

pip uninstall lftools -y

git clone https://gerrit.linuxfoundation.org/infra/releng/lftools
cd lftools
git fetch https://gerrit.linuxfoundation.org/infra/releng/lftools refs/changes/33/5133/5
git checkout FETCH_HEAD
pip install -e .
cd ..

lftools deploy nexus-stage "$NEXUS_URL" "$STAGING_PROFILE_ID" "$WORKSPACE/m2repo"
echo "Error code: $?"
