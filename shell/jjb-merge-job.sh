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
echo "---> jjb-merge-job.sh"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

jenkins-jobs update --recursive --delete-old --workers 4 --exclude jjb-test jjb
