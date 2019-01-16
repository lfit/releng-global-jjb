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
set -xe

GIT_URL=${GIT_URL}
RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")
GERRIT_HOST=${GERRIT_HOST}

clone_repo(){
echo "--> Cloning $repo"
if [ ! -d "$repo" ]; then
    git clone "$GIT_URL"/"$repo".git "$repo"
fi
}

check_if_ref_exists(){
clone_repo
cd "$repo"
if git rev-list refs/heads/master | grep "$ref"; then
  echo "$ref exists"
  REF_EXISTS=true
  cd -
else
  echo "$ref Does not exist please submit a valid ref for branching"
  exit 1
fi
}

run_merge(){
unset NEW_FILES
if [[ $REF_EXISTS = true && "$JOB_NAME" =~ "merge" ]]; then
  ssh -n -f -p 29418 $GERRIT_HOST gerrit create-branch "$repo" "$branch" "$ref"
fi
}

main(){
for release_file in $RELEASE_FILES; do
    while read -r repo branch ref; do
        echo "$repo" "$branch" "$ref"
        branches="$(git ls-remote $GIT_URL/$repo.git "refs/heads/$branch")"
        if ! [ -z "$branches" ]; then
            echo "refs/heads/$branch already exists at $ref ($branches)"
        else
            run_merge
        fi
      done
done < <(python global-jjb/shell/releng-release-repos.py -b -f "$release_file")
}

check_if_ref_exists
main
