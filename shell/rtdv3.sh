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
echo "---> rtdv3.sh"
set -euo pipefail

watchbuild(){
  echo "INFO: Running build against branch $1"
  local buildid
  local result
  buildid=$(lftools rtd project-build-trigger "$rtdproject" "$1" | jq '.build.id')

  result=null
  while [[ "$result" == null ]]; do
    sleep 10
    result=$(lftools rtd project-build-details "$rtdproject" "$buildid"  | jq '.success')
    echo "INFO Current result of running build $result"
    if [[ $result == failed ]]; then
      echo "INFO: read the docs build completed with status: $result"
      exit 1
    fi
  done
  echo "INFO: read the docs build completed with status: $result"
}

project_dashed="${PROJECT////-}"
umbrella=$(echo "$GERRIT_URL" | awk -F'.' '{print $2}')
if [[ "$SILO" == "sandbox" ]]; then
  rtdproject="$umbrella-$project_dashed-test"
else
  rtdproject="$umbrella-$project_dashed"
fi

#MASTER_RTD_PROJECT as a global jenkins cnt
masterproject="$umbrella-$MASTER_RTD_PROJECT"

#Exceptions needed for onap, due to importing their old docs.
if [[ $masterproject == "onap-doc" ]]; then
  masterproject="onap"
fi
if [[ $rtdproject == "onap-doc" ]]; then
  rtdproject="onap"
fi


echo "INFO:"
echo "INFO: Project: $PROJECT"
echo "INFO: Read the Docs Sub Project: https://$rtdproject.readthedocs.io"
echo "INFO: Read the Docs Master Project: https://$masterproject.readthedocs.io"


if [[ "$JOB_NAME" =~ "verify" ]]; then
  if [[ "$(lftools rtd project-details "$rtdproject" | yq -r '.detail')" == "Not found." ]]; then
    echo "INFO: Project not found, merge will create project https://$rtdproject.readthedocs.io"
  fi

echo "INFO: Verify job completed"

fi

if [[ "$JOB_NAME" =~ "merge" ]]; then
echo "INFO: Performing merge action"

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
      cnt=$(($cnt+1))
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
      echo "INFO: subproject $rtdproject relationship already created"
    else
      echo "INFO: Creating subproject relationship"
      lftools rtd subproject-create "$masterproject" "$rtdproject"
      echo "INFO sleeping for 10 seconds"
      sleep 10
    fi
  fi

  # api v3 method does not update /latest/ when master is triggered.
  # Also, when we build anything other than master we want to trigger /stable/ as well.
  # allow projects to change their landing page from latest to branch_name

  current_version="$(lftools rtd project-details "$rtdproject" | yq -r .default_version)"
  if [[ -z ${DEFAULT_VERSION:-} ]]; then
    echo "DEFAULT_VERSION (default-version) value cannot be empty"
    exit 1
  fi
  default_version="${DEFAULT_VERSION}"

  echo "INFO: current default version $current_version"
  if [[ $current_version != "$default_version" ]]; then
    echo "INFO: Setting rtd landing page to $default_version"
    lftools rtd project-update "$rtdproject" default_version="$default_version"
  fi

  if [[ $GERRIT_BRANCH == "master" ]]; then
    echo "INFO: triggering $rtdproject latest"
    watchbuild latest
  else

    #read the docs only understands lower case branch names
    branch=$(echo "$GERRIT_BRANCH" | tr '[:upper:]' '[:lower:]')
    echo "INFO: Checking if read the docs has seen branch $branch"

    #if this is 200 "null" Then run discover branch
    if [[ $(lftools rtd project-version-details "$rtdproject" "$branch" | jq '.active') == "null" ]]; then
      echo "INFO: read the docs has not seen branch $branch for project $rtdproject"
      echo "INFO: triggering $rtdproject latest to instantiate new branch discovery"
      watchbuild latest
    fi

    echo "INFO: triggering $rtdproject $branch"
    watchbuild "$branch"

    #Make newly discovered branches visible in the u/i
    isactive=$(lftools rtd project-version-details "$rtdproject" "$branch" | jq '.active')
    if [[ "$isactive" == false ]]; then
      echo "INFO: Marking $branch as active for project $rtdproject"
      lftools rtd project-version-update "$rtdproject" "$branch" true
    fi

  fi
fi
