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

workers="${JJB_WORKERS:-0}"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf_activate_venv jenkins-job-builder

jenkins-jobs update --recursive --delete-old --workers "$workers" jjb/
