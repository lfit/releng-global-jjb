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
# Deletes all jobs on a Jenkins Sandbox system.
echo "---> jenkins-sandbox-cleanup.sh"

set -eux -o pipefail

bash -c "/usr/bin/yes 2>/dev/null || true" | jenkins-jobs -s sandbox delete-all
