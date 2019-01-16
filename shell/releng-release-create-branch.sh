#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -xe

GIT_URL=${GIT_URL}
RELEASE_FILES=$(git diff HEAD^1 --name-only -- "releases/")
#this wont work if there are multiple files
STREAM=$(git diff HEAD^1 --name-only -- "releases/" | awk -F"/" '{print $2}')

clone_repo(){
echo "--> Cloning $repo"
if [ ! -d $repo ]; then
    git clone $GIT_URL/$repo.git $repo
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
  ssh -n -f -p 29418 gerrit.opnfv.org gerrit create-branch "$repo" "$branch" "$ref"
  python releases/scripts/create_jobs.py -f $release_file
  NEW_FILES=$(git status --porcelain --untracked=no | cut -c4-)
fi
if [ -n "$NEW_FILES" ]; then
  git add $NEW_FILES
  git commit -sm "Create Stable Branch Jobs for $(basename $release_file .yaml)"
  git push origin HEAD:refs/for/master
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
