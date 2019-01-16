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

#this wont work if there are multiple files changed.
STREAM=$(git diff HEAD^1 --name-only -- "releases/" | awk -F"/" '{print $2}')

echo "--> Verifying $RELEASE_FILES."
for release_file in $RELEASE_FILES; do

    # Verify tag for each repo exist and are attached to commits on stable-branch
    while read -r repo tag ref
    do
      echo "--> Cloning $repo"
      if [ ! -d $repo ]; then
          git clone $GIT_URL/$repo.git $repo
      fi
      pushd $repo &> /dev/null

      echo "--> Checking for tag: $tag"
      if ! (git tag -l | grep $tag &> /dev/null); then
          echo "$tag does not exist"
          TAG_EXISTS=false
      else
          git cat-file commit $tag
          TAG_EXISTS=true
      fi

      echo "--> Checking if $ref is on stable/$STREAM"
      if ! (git branch -a --contains $ref | grep "stable/$STREAM"); then
          echo "--> ERROR: $ref for $repo is not on stable/$STREAM!"
          # If the tag exists but is on the wrong ref, there's nothing
          # we can do. But if the tag neither exists nor is on the
          # correct branch we need to fail the verification.
          if [ $TAG_EXISTS = false ]; then
              exit 1
          fi
      else
          if [[ $TAG_EXISTS = false && "$JOB_NAME" =~ "merge" ]]; then
              # If the tag doesn't exist and we're in a merge job,
              # everything has been verified up to this point and we
              # are ready to create the tag.
              git config --global user.name "jenkins-ci"
              git config --global user.email "jenkins-opnfv-ci@opnfv.org"
              echo "--> Creating $tag tag for $repo at $ref"
              git tag -am "$tag" $tag $ref
              echo "--> Pushing tag"
              git push origin $tag
          else
              # For non-merge jobs just output the ref info.
              git show -s --format="%h %s %d" $ref
          fi
      fi

      popd &> /dev/null
      echo "--> Done verifing $repo"
    done < <(python global-jjb/shell/releng-release-repos.py -f "$release_file")

done
