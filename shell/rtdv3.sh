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

#MASTER_RTD_PROJECT as a global jenkins cnt
masterproject="$umbrella-$MASTER_RTD_PROJECT"

echo "INFO:"
echo "INFO: Project: $PROJECT"
echo "INFO: Read the Docs Project: https://$rtdproject.readthedocs.io"
echo "INFO: Read the Docs master Project: https://$masterproject.readthedocs.io"


if [[ "$JOB_NAME" =~ "verify" ]]; then
  if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
    echo "INFO: Project not found, merge will create project https://$rtdproject.readthedocs.io"
  fi

echo "INFO: Merge will run"
echo "INFO: lftools rtd project-build-trigger $rtdproject $STREAM"

fi

if [[ "$JOB_NAME" =~ "merge" ]]; then

  # This retuns null if project exists.
  project_exists=false
  project_created=false

  declare -i cnt=0
  while [[ $project_exists == "false" ]]; do
    if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
      echo "INFO: Project not found"
        if [[ $project_created == "false" ]]; then
          echo "INFO: Creating project https://$rtdproject.readthedocs.io"
          lftools rtd project-create "$rtdproject" "$GERRIT_URL/$PROJECT" git "https://$rtdproject.readthedocs.io" py en
          project_created="true"
        fi
        echo "INFO sleeping for 30 seconds $cnt times"
      sleep 30
      ((cnt+=1))
      if (( cnt >= 20 )); then
        echo "INFO: Job has timed out"
        exit 1
      fi
    else
      echo "INFO: Project exists in read the docs as https://$rtdproject.readthedocs.io"
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
      echo "INFO: subproject relationship already created"
    else
      echo "INFO: Need to create subproject relationship"
      lftools rtd subproject-create "$masterproject" "$rtdproject"
      echo "INFO sleeping for 10 seconds"
      sleep 10
    fi
  fi

  lftools rtd project-build-trigger "$rtdproject" "$STREAM"
fi
