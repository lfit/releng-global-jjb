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
set -e -o pipefail

GIT_URL=${GIT_URL}
RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")


#need pip install jsonschema for this.
echo "--> Verifying $RELEASE_FILES."
for release_file in $RELEASE_FILES; do
    # Verify the release file schema
    python releases/scripts/verify_schema.py \
    -s releases/schema.yaml \
    -y $release_file
done

for release_file in $RELEASE_FILES; do
    while read -r repo branch ref; do
        echo "$repo" "$branch" "$ref"
        unset branch_actual
        branch_actual="$(git ls-remote "$GIT_URL/$repo.git" "refs/heads/$branch" | awk '{print $1}')"

        if [ -n "$branch_actual" ]; then
            echo "$repo refs/heads/$branch already exists at $branch_actual"
            echo "RUN releng-release-create-venv.sh"
            source global-jjb/shell/releng-release-tagging.sh
        else
            echo "This is a branching job"
            source global-jjb/shell/releng-release-create-branch.sh
        fi

    done  < <(python global-jjb/shell/releng-release-repos.py -b -f "$release_file")
done
