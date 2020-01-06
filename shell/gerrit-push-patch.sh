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
echo "---> gerrit-push-patch.sh"
# Push a change to Gerrit if files modified in repository.
#
# The script requires to install the minimum version 1.25 of git-review using
# virtualenv and pip install which supports `--reviewers` option.
#
# The script allows a job to push a patch to Gerrit in an automated fashion.
# This is meant for tasks that creates the same patch regularly and needs the
# ability to detect if an unreviewed patch already exists. In which case it
# will update the existing patch.
#
# Note: This patch assumes the $WORKSPACE contains the project repo with
#       'Changes to be committed'.
#
# This script requires the following JJB variables to be passed in:
#
#   $PROJECT              : Gerrit project-name
#   $GERRIT_COMMIT_MESSAGE: Commit message to assign to commit
#   $GERRIT_HOST          : Gerrit hostname
#   $GERRIT_TOPIC         : Gerrit topic, please make a unique topic
#   $GERRIT_USER          : Gerrit user
#   $REVIEWERS_EMAIL      : Reviewers email

# TODO: remove the workaround when v1.26 is available on all images
# Workaround for git-review bug in v1.24
# https://storyboard.openstack.org/#!/story/2001081

set -eufo pipefail

# No reason to continue if there are no 'Changes to be committed'
# Look for: new, modified or deleted
modified_list=$(git status --porcelain | egrep "^A |^M |^D " | awk '{print $2}')
if [[ -z $modified_list ]]; then
    echo "INFO: Nothing to commit"
    exit 0
fi

echo "INFO: Committing: $modified_list"

# shellcheck disable=SC1090
source ~/lf-env.sh

# DEBUG no longer installing setuptools
lf-activate-venv git-review

# DEBUG
pip --version
type git-review
git-review --version
echo "####  DEBUG  ####"
git status
echo "####  DEBUG  ####"
git diff
echo "####  DEBUG  ####"

job=$JOB_NAME/$BUILD_NUMBER

set -x #DEBUG
change_id=$(ssh -p 29418 "$GERRIT_USER@$GERRIT_HOST"     \
            gerrit query limit: 1  owner: self  is: open \
                project: "$PROJECT"                      \
                message: "$GERRIT_COMMIT_MESSAGE"        \
                topic:   "$GERRIT_TOPIC"                 \
            | grep 'Change-Id:' | awk '{ print $2 }')

if [[ -z $change_id ]]; then
    message="Job: $job"
else
    message="Job: $job\nChange-Id: $change_id"
fi
git commit -sm "$GERRIT_COMMIT_MESSAGE" -m "$message"
git show # DEBUG

git status
git remote add gerrit "ssh://$GERRIT_USER@$GERRIT_HOST:29418/$PROJECT.git"

# If the reviewers email is empty then use a default
reviewers_email=${REVIEWERS_EMAIL:-$GERRIT_USER@$GERRIT_HOST}

# Since the Job Number is included in the commit message, the 'git review' will
# not fail because 'no new changes'. Let the build fail if 'git review' fails
# DEBUG
git review --yes -t "$GERRIT_TOPIC" --reviewers "$reviewers_email" --dry-run
#git review --yes -t "$GERRIT_TOPIC" --reviewers "$reviewers_email"
exit 1 # DEBUG
