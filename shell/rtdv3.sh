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

# shellcheck disable=SC1090
. ~/lf-env.sh
# An agent's ~/lf-env.sh is copied when it boots, so may predate lftools-uv.
if ! declare -F lftools-uv > /dev/null; then
    lf_env="$(mktemp)"
    lf_env_url="https://raw.githubusercontent.com/lfit/releng-global-jjb"
    wget -nv -O "$lf_env" "$lf_env_url/${GLOBAL_JJB_VERSION:-master}/jenkins-init-scripts/lf-env.sh" || true
    # shellcheck disable=SC1090
    source "$lf_env"
    rm -f "$lf_env"
    if ! declare -F lftools-uv > /dev/null; then
        echo "ERROR: lf-env.sh has no lftools-uv function" >&2
        exit 1
    fi
fi

# Fetch lftools-uv here, in the main shell: the queries below run it in
# command substitutions, which cannot keep what a fetch found.
lftools-uv --version > /dev/null

# Print the JSON 'lftools-uv rtd ARGS... --json' reports. With '--missing
# WHAT', return 2 quietly when lftools-uv reports exactly WHAT, worded as it
# words it, as not found: "Project 'SLUG'" or "Version 'V' of project 'SLUG'".
# Any other failure shows its error and returns 1, so an outage or a rejected
# token cannot pass for "not found".
rtd_json(){
    local missing="" found="" err out line rc=0
    if [[ $1 == --missing ]]; then
        missing="Error: $2 not found"
        shift 2
    fi
    err="$(mktemp)"
    out="$(lftools-uv rtd "$@" --json 2> "$err")" || rc=$?
    if (( rc == 0 )); then
        rm -f "$err"
        printf '%s\n' "$out"
        return 0
    fi
    if [[ -n $missing ]] && (( rc == 1 )); then
        while IFS= read -r line; do
            if [[ $line == "$missing" || $line == "$missing: "* ]]; then
                found=1
            fi
        done < "$err"
    fi
    if [[ -n $found ]]; then
        rm -f "$err"
        return 2
    fi
    cat "$err" >&2
    rm -f "$err"
    echo "ERROR: lftools-uv rtd $* failed with exit status $rc" >&2
    return 1
}

# Return 0 when Read the Docs has project $1, and 1 when it reports the
# project missing. Stop the job when it cannot tell.
rtd_project_exists(){
    local rc=0
    rtd_json --missing "Project '$1'" project-details "$1" > /dev/null || rc=$?
    case $rc in
        0) return 0 ;;
        2) return 1 ;;
        *) exit 1 ;;
    esac
}

# Print the Read the Docs version slug of branch $1. Read the Docs lowercases
# a branch name and replaces each run of characters outside [a-z0-9._-] with a
# hyphen, so branch stable/scandium is version stable-scandium. Requests pass
# the branch with --from-branch, so lftools-uv's version_slug() applies the
# rule; this copy names the version in messages and in the not-found match,
# so a difference between the two fails the job rather than passing unseen.
rtd_version_slug(){
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

# Print "active" or "inactive" for the version of branch $2 in project $1, or
# "missing" when Read the Docs has not seen it. Stop the job when it cannot
# tell.
rtd_version_state(){
    local version details active rc=0
    version="$(rtd_version_slug "$2")"
    details="$(rtd_json --missing "Version '$version' of project '$1'" \
        project-version-details "$1" "$2" --from-branch)" || rc=$?
    case $rc in
        0) ;;
        2) echo missing; return 0 ;;
        *) exit 1 ;;
    esac
    active="$(jq -r '.active' <<< "$details")"
    case $active in
        true) echo active ;;
        false) echo inactive ;;
        *)
            echo "ERROR: version $version of project $1 has no active flag: $active" >&2
            exit 1
            ;;
    esac
}

# Build branch $1 and wait for the build, polling every 10 seconds for up to
# an hour. Stop the job unless the build succeeds.
watchbuild(){
    echo "INFO: Running build against branch $1"
    local trigger buildid details result
    local -i polls=360
    trigger="$(rtd_json project-build-trigger "$rtdproject" "$1" --from-branch)"
    buildid="$(jq -r '.build.id // empty' <<< "$trigger")"
    if [[ ! $buildid =~ ^[0-9]+$ ]]; then
        echo "ERROR: Read the Docs returned no build id for $1: $trigger" >&2
        exit 1
    fi

    # Read the Docs reports success as null until the build finishes.
    while true; do
        sleep 10
        details="$(rtd_json project-build-details "$rtdproject" "$buildid")"
        result="$(jq -r '.success' <<< "$details")"
        echo "INFO Current result of running build $result"
        case $result in
            true) break ;;
            false)
                echo "ERROR: read the docs build $buildid failed" >&2
                exit 1
                ;;
            null) ;;
            *)
                echo "ERROR: read the docs build $buildid has no success flag: $result" >&2
                exit 1
                ;;
        esac
        polls=$((polls - 1))
        if (( polls <= 0 )); then
            echo "ERROR: read the docs build $buildid did not finish within an hour" >&2
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
    if ! rtd_project_exists "$rtdproject"; then
        echo "INFO: Project not found, merge will create project https://$rtdproject.readthedocs.io"
    fi
    echo "INFO: Verify job completed"
fi

if [[ "$JOB_NAME" =~ "merge" ]]; then
    echo "INFO: Performing merge action"

    project_exists=false
    project_created=false

    declare -i cnt=0
    while [[ $project_exists == "false" ]]; do
        if ! rtd_project_exists "$rtdproject"; then
            echo "INFO: Project not found"
            if [[ $project_created == "false" ]]; then
                echo "INFO: Creating project https://$rtdproject.readthedocs.io"
                lftools-uv rtd project-create "$rtdproject" "$GERRIT_URL/$PROJECT" \
                    git "https://$rtdproject.readthedocs.io" py en
                project_created="true"
            fi
            echo "INFO sleeping for 30 seconds $cnt times"
            sleep 30
            cnt=$((cnt+1))
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
        subprojects="$(rtd_json subproject-list "$masterproject")"
        if ! jq -e '.subprojects | type == "array"' <<< "$subprojects" > /dev/null; then
            echo "ERROR: no subproject list for $masterproject: $subprojects" >&2
            exit 1
        fi

        if jq -e --arg p "$rtdproject" 'any(.subprojects[]; . == $p)' \
                <<< "$subprojects" > /dev/null; then
            echo "INFO: subproject $rtdproject relationship already created"
        else
            echo "INFO: Creating subproject relationship"
            lftools-uv rtd subproject-create "$masterproject" "$rtdproject"
            echo "INFO sleeping for 10 seconds"
            sleep 10
        fi
    fi

    # api v3 method does not update /latest/ when master is triggered.
    # Also, when we build anything other than master we want to trigger /stable/ as well.
    # allow projects to change their landing page from latest to branch_name

    project_details="$(rtd_json project-details "$rtdproject")"
    current_version="$(jq -r .default_version <<< "$project_details")"
    if [[ -z ${DEFAULT_VERSION:-} ]]; then
        echo "DEFAULT_VERSION (default-version) value cannot be empty"
        exit 1
    fi
    default_version="${DEFAULT_VERSION}"

    echo "INFO: current default version $current_version"
    if [[ $current_version != "$default_version" ]]; then
        echo "INFO: Setting rtd landing page to $default_version"
        lftools-uv rtd project-update "$rtdproject" default_version="$default_version"
    fi

    if [[ $GERRIT_BRANCH == "master" ]]; then
        echo "INFO: triggering $rtdproject latest"
        watchbuild latest
    else

        # Read the Docs addresses a branch by its version slug
        branch="$GERRIT_BRANCH"
        version="$(rtd_version_slug "$branch")"
        echo "INFO: Checking if read the docs has seen branch $branch as version $version"

        version_state="$(rtd_version_state "$rtdproject" "$branch")"
        if [[ $version_state == missing ]]; then
            echo "INFO: read the docs has not seen version $version for project $rtdproject"
            echo "INFO: triggering $rtdproject latest to instantiate new branch discovery"
            watchbuild latest
        fi

        echo "INFO: triggering $rtdproject $version"
        watchbuild "$branch"

        #Make newly discovered branches visible in the u/i
        version_state="$(rtd_version_state "$rtdproject" "$branch")"
        if [[ $version_state == inactive ]]; then
            echo "INFO: Marking $version as active for project $rtdproject"
            lftools-uv rtd project-version-update "$rtdproject" "$branch" true --from-branch
        fi

    fi
fi
