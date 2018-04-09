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
# This script push a change to a project, when there is a change in the
# repository.
#
# The script requires to install git-review using virtualenv to the latest
# version that supports `--reviewers` option, available through pip install.
# CentOS images are bundled with older versions where the --reviewers option
# does not work.
#
# The scripts allows a job to push a patch to Gerrit in an automated fashion.
# This is meant for tasks that creates the same patch regularly and needs the
# ability to detect if an unreviewed patch already exists. In which case it
# will update the existing patch.
#
# Note: This patch assumes the $WORKSPACE contains the project repo with
#       the files changed already "git add" and waiting for a "git commit" call.
#
# This script requires the following JJB variables to be passed in:
#
#   $PROJECT              : Gerrit project-name
#   $GERRIT_COMMIT_MESSAGE: Commit message to assign to commit.
#   $GERRIT_HOST          : Gerrit hostname
#   $GERRIT_TOPIC         : Gerrit topic, please make a unique topic.
#   $GERRIT_USER          : Gerrit user
#   $REVIEWERS_EMAIL      : Reviewers email as a comma separated string.

# TODO: remove the workaround when v1.26 is available on all images
# Workaround for git-review bug in v1.24
# https://storyboard.openstack.org/#!/story/2001081
set +u  # Allow unbound variables for virtualenv
virtualenv --quiet "/tmp/v/git-review"
# shellcheck source=/tmp/v/git-review/bin/activate disable=SC1091
source "/tmp/v/git-review/bin/activate"
pip install --quiet --upgrade pip setuptools
pip install --quiet --upgrade git-review
set -u
# End git-review workaround

# Remove any leading or trailing quotes surrounding the strings
# which can cause parse errors when passed as CLI options to commands
PROJECT="$(echo $PROJECT | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
GERRIT_COMMIT_MESSAGE="$(echo $GERRIT_COMMIT_MESSAGE | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
GERRIT_HOST="$(echo $GERRIT_HOST | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
GERRIT_TOPIC="$(echo $GERRIT_TOPIC | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
GERRIT_USER="$(echo $GERRIT_USER | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"
REVIEWERS_EMAIL="$(echo $REVIEWERS_EMAIL | sed "s/^\([\"']\)\(.*\)\1\$/\2/g")"

# shellcheck disable=SC1083
CHANGE_ID=$(ssh -p 29418 "$GERRIT_USER@$GERRIT_HOST" gerrit query \
               limit:1 owner:self is:open project:"$PROJECT" \
               message: "$GERRIT_COMMIT_MESSAGE" \
               topic: "$GERRIT_TOPIC" | \
               grep 'Change-Id:' | \
               awk '{{ print $2 }}')

if [ -z "$CHANGE_ID" ]; then
   git commit -sm "$GERRIT_COMMIT_MESSAGE"
else
   git commit -sm "$GERRIT_COMMIT_MESSAGE" -m "Change-Id: $CHANGE_ID"
fi

git status
git remote add gerrit "ssh://$GERRIT_USER@$GERRIT_HOST:29418/$PROJECT.git"

# if the reviewers email is empty then use a default
REVIEWERS_EMAIL=${REVIEWERS_EMAIL:-"$GERRIT_USER@$GERRIT_HOST"}

# Don't fail the build if this command fails because it's possible that there
# is no changes since last update.
# shellcheck disable=SC1083
git review --yes -t "$GERRIT_TOPIC" --reviewers "$REVIEWERS_EMAIL" || true
