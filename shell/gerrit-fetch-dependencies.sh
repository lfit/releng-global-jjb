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
# Fetches patches all projects provided by comment trigger
#
# Takes a list of Gerrit patches and fetches all projects and cherry-pick
# patches for projects. The trigger is
#     'recheck: SPACE_SEPERATED_LIST_OF_PATCHES'
#
# NOTE: This script assumes the user will provide the correct dependency order
#       via the PATCHES list.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

REPOS_DIR="$WORKSPACE/.repos"

IFS=" " read -r -a PATCHES <<< "$(echo "$GERRIT_EVENT_COMMENT_TEXT" | grep 'recheck:' | awk -F: '{print $2}')"

# Workaround for git-review bug in v1.24
# https://storyboard.openstack.org/#!/story/2001081
set +u  # Allow unbound variables for virtualenv
virtualenv --quiet "/tmp/v/git-review"
# shellcheck source=/tmp/v/git-review/bin/activate disable=SC1091
source "/tmp/v/git-review/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade git-review
set -u
# End git-review workaround

projects=()
for patch in $(echo "${PATCHES[@]}"); do
    json=$(curl -s "$GERRIT_URL/changes/$patch" | sed -e "s/)]}'//")
    project=$(echo "$json" | jq -r '.project')
    branch=$(echo "$json" | jq -r '.branch')

    if [ "$GERRIT_CHANGE_NUMBER" == "$patch" ]; then
        echo "WARN: GERRIT_CHANGE and $patch are one and the same. Ignoring patch..."
        continue
    fi

    if [ ! -d "$REPOS_DIR/$project" ]; then
        git clone -q --depth 1 -b "$branch" "$GERRIT_URL/$project" "$REPOS_DIR/$project"

        # This array will be used later to determine project build order.
        projects+=("$project")
    fi

    pushd "$REPOS_DIR/$project"
    # If remote gerrit already exists just make sure path is expected
    if ! git remote add gerrit "$GERRIT_URL/$project" > /dev/null 2>&1; then
        git remote set-url gerrit "$GERRIT_URL/$project"
    fi
    git review --cherrypick="$patch"
    popd
done

# This script should be a macro which re-inject's the projects variable back
# into the build so a script later on can use it.
echo "DEPENDENCY_BUILD_ORDER=${projects[*]}" > "$WORKSPACE/.dependency.properties"
