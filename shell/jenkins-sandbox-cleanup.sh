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

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv jenkins-job-builder

yes | jenkins-jobs -s sandbox delete-all

# Recreate the All default view.
cat << 'EOF' > all-view.yaml
- view:
    name: All
    view-type: all
EOF
jenkins-jobs -s sandbox update -v all-view.yaml
