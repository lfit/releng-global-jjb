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
echo "---> gerrit-branch-lock.sh"
# Generates a patch to lock|unlock a branch in Gerrit
#
# Assumes that the project repository was cloned via ssh and thus uses ssh to
# install the git commit hook.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

git fetch origin refs/meta/config:config
git checkout config

install_gerrit_hook() {
    ssh_url=$(git remote show origin | grep Fetch | grep 'ssh://' \
        | awk -F'/' '{print $3}' | awk -F':' '{print $1}')
    ssh_port=$(git remote show origin | grep Fetch | grep 'ssh://' \
        | awk -F'/' '{print $3}' | awk -F':' '{print $2}')

    if [ -z "$ssh_url" ]; then
        echo "ERROR: Gerrit SSH URL not found."
        exit 1
    fi

    scp -p -P "$ssh_port" "$ssh_url":hooks/commit-msg .git/hooks/
    chmod u+x .git/hooks/commit-msg
}
install_gerrit_hook

# Groups must be mapped in the groups file before they can be used
if ! grep 'Registered Users'; then
    echo -e "global:Registered-Users\tRegistered Users" >> groups
    git add groups
fi

mode=$(echo "$GERRIT_EVENT_COMMENT_TEXT" | grep branch | awk '{print $1}')
case $mode in
    lock)
        echo "Locking branch: $GERRIT_BRANCH"
        git config -f project.config \
            "access.refs/heads/${GERRIT_BRANCH}.exclusiveGroupPermissions" \
            "submit"
        git config -f project.config \
            "access.refs/heads/${GERRIT_BRANCH}.submit" \
            "block group Registered Users"
        git commit -asm "Lock branch $GERRIT_BRANCH"
        ;;

    unlock)
        echo "Unlocking branch: $GERRIT_BRANCH"
        git config -f project.config --remove-section \
            "access.refs/heads/${GERRIT_BRANCH}" || true
        git commit -asm "Unlock branch $GERRIT_BRANCH"
        ;;

    *)
        echo "ERROR: Unknown mode selected '$mode'."
        exit 1
        ;;
esac

git diff HEAD~1
git push origin HEAD:refs/for/refs/meta/config
