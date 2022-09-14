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
# Push a job to jenkins-sandbox via Gerrit / GitHub comment
# Comment Pattern: jjb-deploy JOB_NAME
# JOB_NAME: Can also include * wildcards too. Additional parameters are ignored.
echo "---> jjb-deploy-job.sh"

# Ensure we fail the job if any steps fail.
set -uef -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

# Version controlled by JJB_VERSION
lf_activate_venv --python python3 --venv-file /tmp/.jjb_venv jenkins-job-builder

# Fetch patch if gerrit project matches the jjb-deploy project
if [ "${GERRIT_PROJECT}" == "${PROJECT}" ]; then
    echo "-----> Fetching ${PROJECT} patch"
    git fetch origin "$GERRIT_REFSPEC" && git checkout FETCH_HEAD
fi

# If not Gerrit Trigger than assume GitHub
COMMENT="${GERRIT_EVENT_COMMENT_TEXT:-$ghprbCommentBody}"
JOB_NAME=$(echo "$COMMENT" | grep jjb-deploy | awk '{print $2}')

# Strip all * characters to prevent pushing all jobs to Jenkins
if [ -z "${JOB_NAME//\*/}" ]; then
    echo "ERROR: JOB_NAME cannot be empty or '*'."
    exit 1
fi

echo "Deploying Job $JOB_NAME to sandbox"
jenkins-jobs -s sandbox update --jobs-only --recursive --workers 4 jjb/ "$JOB_NAME"
