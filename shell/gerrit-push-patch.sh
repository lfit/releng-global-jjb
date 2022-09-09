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
# Need to use git-review >= 1.28 to be compatible with Gerrit 3
#
# The script allows a job to push a patch to Gerrit in an automated fashion.
# This is meant for tasks that creates the same patch regularly and needs the
# ability to detect if an unreviewed patch already exists. In which case it
# will update the existing patch.
#
# Note: This script expects $WORKSPACE to point to a project git repo that
# may contain staged commits. This script will exit with OK status if no
# staged commits are present, otherwise the staged commits will be commited and
# a gerrit review will be created.
#
# This script expects the following environment variables to be set in the
# JJB configuration
#
#   $PROJECT              : Gerrit project-name
#   $GERRIT_COMMIT_MESSAGE: Commit message to assign to commit
#   $GERRIT_HOST          : Gerrit hostname
#   $GERRIT_TOPIC         : Gerrit topic, please make a unique topic
#   $GERRIT_USER          : Gerrit user
#   $REVIEWERS_EMAIL      : Reviewers email

set -eufo pipefail

# No reason to continue if there are no staged commits
staged_commits=$(git diff --cached --name-only)
if [[ -z $staged_commits ]]; then
    echo "INFO: Nothing to commit"
    exit 0
fi

echo -e "INFO: Staged for commit:\n$staged_commits\n"

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "git-review==2.3.1"

# Query for a pre-existing gerrit review
query_result=$(ssh -p 29418 "$GERRIT_USER@$GERRIT_HOST" gerrit query \
                limit:1 owner:self is:open project:"$PROJECT"        \
                message: "$GERRIT_COMMIT_MESSAGE"                    \
                topic: "$GERRIT_TOPIC")

# Extract the change_id from the query_result
job=$JOB_NAME/$BUILD_NUMBER
# If available, add change_id to commit message
if change_id=$(echo "$query_result" | grep 'Change-Id:' | awk '{print $2}'); then
    echo "NOTE: Found gerrit review: $change_id"
    message="Job: $job"$'\n'"Change-Id: $change_id"
else
    echo "NOTE: No gerrit review found"
    message="Job: $job"
fi
git commit -sm "$GERRIT_COMMIT_MESSAGE

$message"

git status
git remote add gerrit "ssh://$GERRIT_USER@$GERRIT_HOST:29418/$PROJECT.git"

# If the reviewers email is unset/empty then use a default
reviewers_email=${REVIEWERS_EMAIL:-"$GERRIT_USER@$GERRIT_HOST"}

git review --yes -t "$GERRIT_TOPIC" --reviewers "$reviewers_email"
