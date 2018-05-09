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
set -e -o pipefail

# shellcheck source=/tmp/v/jenkins-job-builder/bin/activate disable=SC1091
source "/tmp/v/jenkins-job-builder/bin/activate"

echo "-----> Fetching project"
git fetch origin "$GERRIT_REFSPEC" && git checkout FETCH_HEAD

# If not Gerrit Trigger than assume GitHub
COMMENT="${GERRIT_EVENT_COMMENT_TEXT:-$ghprbCommentBody}"
JOB_NAME=$(echo "$COMMENT" | grep jjb-deploy | awk '{print $2}')

# Strip all * characters to prevent pushing all jobs to Jenkins
if [ -z "${JOB_NAME//\*/}" ]; then
    echo "ERROR: JOB_NAME cannot be empty or '*'."
    exit 1
fi

jenkins-jobs update --jobs-only --recursive --workers 4 jjb/ "$JOB_NAME"
