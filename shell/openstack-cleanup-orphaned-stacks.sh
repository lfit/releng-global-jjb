#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017, 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Scans OpenStack for orphaned stacks
echo "---> Orphaned stacks"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

stack_in_jenkins() {
    # Usage: check_stack_in_jenkins STACK_NAME JENKINS_URL [JENKINS_URL...]
    # Returns: 0 If stack is in Jenkins and 1 if stack is not in Jenkins.

    STACK_NAME="${1}"

    builds=()
    for jenkins in "${@:2}"; do
        PARAMS="tree=computer[executors[currentExecutable[url]],oneOffExecutors[currentExecutable[url]]]"
        PARAMS=$PARAMS"&xpath=//url&wrapper=builds"
        JENKINS_URL="$jenkins/computer/api/json?$PARAMS"
        resp=$(curl -s -w "\\n\\n%{http_code}" --globoff -H "Content-Type:application/json" "$JENKINS_URL")
        json_data=$(echo "$resp" | head -n1)
        status=$(echo "$resp" | awk 'END {print $NF}')

        if [ "$status" != 200 ]; then
            >&2 echo "ERROR: Failed to fetch data from $JENKINS_URL with status code $status"
            >&2 echo "$resp"
            exit 1
        fi

        if [[ "${jenkins}" == *"jenkins."*".org" ]] || [[ "${jenkins}" == *"jenkins."*".io" ]]; then
            silo="production"
        else
            silo=$(echo "$jenkins" | sed 's/\/*$//' | awk -F'/' '{print $NF}')
        fi
        export silo
        # We purposely want to wordsplit here to combine the arrays
        # shellcheck disable=SC2206,SC2207
        builds=(${builds[@]} $(echo "$json_data" | \
            jq -r '.computer[].executors[].currentExecutable.url' \
            | grep -v null | awk -F'/' '{print ENVIRON["silo"] "-" $6 "-" $7}')
        )
    done

    if [[ "${builds[*]}" =~ $STACK_NAME ]]; then
        return 0
    fi

    return 1
}

#########################
## FETCH ACTIVE BUILDS ##
#########################
# Fetch stack list before fetching active builds to minimize race condition
# where we might be try to delete stacks while jobs are trying to start

mapfile -t OS_STACKS < <(openstack --os-cloud "$os_cloud" stack list \
            -f value -c "Stack Name" -c "Stack Status" \
            --property "stack_status=CREATE_COMPLETE" \
            --property "stack_status=DELETE_FAILED" \
            --property "stack_status=CREATE_FAILED" \
            | awk '{print $1}')

echo "-----> Active stacks"
for stack in "${OS_STACKS[@]}"; do
    echo "$stack"
done


##########################
## DELETE UNUSED STACKS ##
##########################
echo "-----> Delete orphaned stacks"

# Search for stacks not in use by any active Jenkins systems and remove them.
for STACK_NAME in "${OS_STACKS[@]}"; do
    # jenkins_urls intentially needs globbing to be passed a separate params.
    # shellcheck disable=SC2153,SC2086
    if stack_in_jenkins "$STACK_NAME" $jenkins_urls; then
        # No need to delete stacks if there exists an active build for them
        continue
    else
        echo "Deleting orphaned stack: $STACK_NAME"
        lftools openstack --os-cloud "$os_cloud" stack delete --force "$STACK_NAME"
    fi
done
