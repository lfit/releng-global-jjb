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

# This script will make sure that there are no JIRA URLs in the commit
# message. JIRA URLs will break the its-jira plugin

# Ensure we fail the job if any steps fail.
# Do not treat undefined variables as errors as in this case we are allowed
# to have JIRA_URL undefined
set -e -o pipefail
set +u

if [ -z ${JIRA_URL+x} ];
then
  exit 0
else
  JIRA_LINK=$(git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*' || true)
  if [[ ! -z "$JIRA_LINK" ]]
  then
    echo 'Remove JIRA URLs from commit message'
    echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
    exit 1
  fi
fi
