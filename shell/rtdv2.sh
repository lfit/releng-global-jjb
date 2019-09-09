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
echo "---> rtd-verify.sh"
set -euo pipefail

project_dashed="${PROJECT////-}"
umbrella="$(echo "$GERRIT_URL" | awk -F"." '{print $2}')"
if [[ "$SILO" == "sandbox" ]]; then
  rtdproject="$umbrella-$project_dashed-test"
else
  rtdproject="$umbrella-$project_dashed"
fi

#MASTER_RTD_PROJECT as a global jenkins var
masterproject="$umbrella-$MASTER_RTD_PROJECT"

echo "INFO:"
echo "Project: $PROJECT"
echo "Read the Docs Project: $rtdproject"
echo "Read the Docs master Project: $masterproject"


if [[ "$JOB_NAME" =~ "verify" ]]; then
  if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
    echo "Project not found, merge will create project https://$rtdproject.readthedocs.io"
  fi

echo "Merge will run"
echo "lftools rtd project-build-trigger $rtdproject $STREAM"

fi

if [[ "$JOB_NAME" =~ "merge" ]]; then

  # This retuns null if project exists.
  project_exists=false
  while [[ $project_exists == "false" ]]; do
    if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
      echo "Project not found, creating project https://$rtdproject.readthedocs.io"
      lftools rtd project-create "$rtdproject" "$GERRIT_URL/$PROJECT" git "https://$rtdproject.readthedocs.io" py en
      sleep 30
    else
      echo "Project exists in read the docs as https://$rtdproject.readthedocs.io"
      project_exists="true"
    fi
  done

  if [[ "$rtdproject" != "$masterproject" ]]; then
    subproject_exists=false
    while read -r subproject; do
        if [[ "$subproject" == "$rtdproject" ]]; then
          subproject_exists=true
          break
        fi
    done < <(lftools rtd subproject-list "$masterproject")

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
