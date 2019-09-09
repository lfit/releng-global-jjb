#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
#WIP STUFF A new release of lftools is needed to get the needed lftools rtd api bits
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install --upgrade pip
pip install git-review
pip install yq
git review -d 61954
git clone "https://gerrit.linuxfoundation.org/infra/releng/lftools"
pushd lftools

pip install -e .
popd

echo "---> rtd-verify.sh"
set -xe -o pipefail

echo "$PROJECT"
project_dashed="${PROJECT////-}"
umbrella="$(echo "$GERRIT_URL" | awk -F"." '{print $2}')"
rtdproject="$umbrella"-"$project_dashed-test"

#need to define this per project.
masterproject="o-ran-sc-doc-test"

if [[ $PROJECT == "docs" ]] || [[ $PROJECT == "doc" ]] | [[ $PROJECT == "documentation" ]]; then
  echo "This is the master project it has these subprojects"
  lftools rtd subproject-list "$rtdproject"
else
  echo "This is a subproject of the master project"
fi

if [[ "$JOB_NAME" =~ "verify" ]]; then

  # This retuns null if project exists.
  if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
    echo "Project not found, creating project"
    lftools rtd project-create "$rtdproject" "$GERRIT_URL/$PROJECT" git "https://$rtdproject.readthedocs.io" py en

  fi

fi

echo "Merge will run"
echo "lftools rtd project-build-trigger $rtdproject $STREAM"

if [[ "$JOB_NAME" =~ "merge" ]]; then

  if [[ "$rtdproject" != "$masterproject" ]]; then
    subproject_exists=false
    while read -r subproject; do
        if [[ "$subproject" == "$rtdproject" ]]; then
          subproject_exists=true
          break
        fi
    done < <(lftools rtd subproject-list $masterproject)

    if $subproject_exists; then
      echo "subproject relationship already created"
    else
      echo "Need to create subproject relationship"
      lftools rtd subproject-create "$masterproject" "$rtdproject"
      sleep 10
    fi
  fi

  lftools rtd project-build-trigger "$rtdproject" "$STREAM"

fi
