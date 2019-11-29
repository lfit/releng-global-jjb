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
echo "---> jjb-verify-job.sh"

# Ensure we fail the job if any steps fail.
set -euo pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-git-validate-jira-urls
lf-jjb-check-ascii

lf-activate-venv jenkins-job-builder

jenkins-jobs -l DEBUG test --recursive -o archives/job-configs --config-xml jjb/

# NGINX is very sluggish with directories containing large numbers of objects.
# So add another directory level for all directories beginning with {a..z}. All
# other directories left undisturbed at the top level.
cd archives/job-configs
for letter in {a..z}; do
    if ls -d $letter* > /dev/null 2>&1; then
        mkdir .tmp
        mv $letter* .tmp
        mv .tmp $letter
    fi
done

cd ..
echo "INFO: Archiving $(find job-configs -name \*.xml | wc -l) job configurations"
tar -cJf job-configs.tar.xz job-configs

rm -rf job-configs
cd ..
