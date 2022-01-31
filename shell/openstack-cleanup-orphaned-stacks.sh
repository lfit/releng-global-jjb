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
        PARAMS="tree=computer[executors[currentExecutable[url]],"
        PARAMS=$PARAMS"oneOffExecutors[currentExecutable[url]]]"
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
set -x
#########################
## FETCH ACTIVE BUILDS ##
#########################
# Fetch COE cluster list before fetching active stacks. K8s cluster creates
# stack that does not match JOB_NAME, therefore ignore them while processing
# orphaned stacks and handle them separatly.
# The stack naming scheme is limited in the source code to take only first 20
# chars from the JOB_NAME, and the rest is randomly generated value for
# uniqueness:
# https://github.com/openstack/magnum/blob/master/magnum/drivers/heat/driver.py#L202-L212
mapfile -t OS_COE_CLUSTERS_ID < <(openstack --os-cloud "${os_cloud}" coe cluster list \
            -f value -c "uuid" -c "name" \
            | grep -E '(DELETE_FAILED|UNKNOWN|UNHEALTHY)' | awk '{print $1}')

echo "-----> Active clusters -> stacks"
# mapfile -t OS_COE_STACKS_ID
OS_COE_STACKS=()
for cluster_id in "${OS_COE_CLUSTERS_ID[@]}"; do
    # find active stacks id associated with the COE cluster
    stack_id=$(openstack --os-cloud "${os_cloud}" coe cluster show "${cluster_id}" \
                -f value -c "stack_id")
    # get the stack name associated with the COE cluster
    stack_name=$(openstack --os-cloud "${os_cloud}" stack show "${stack_id}" \
                -f value -c "stack_name")
    OS_COE_STACKS+=("${stack_id}")
    echo "clusterid:${cluster_id} -> stackid:${stack_id} stack_name: ${stack_name}"
done

if [[ ${#OS_COE_STACKS[@]} -gt "0" ]]; then
    echo "${OS_COE_STACKS[*]}"
    echo "-----> Active COE cluster stacks"
    for cstack in "${OS_COE_STACKS[@]}"; do
        echo "$cstack"
    done
fi

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
    # Check for COE cluster stack is present
    # shellcheck disable=SC2153,SC2086
    if [[ ${#OS_COE_STACKS[@]} -gt "0" ]] && [[ ${OS_COE_STACKS[*]} =~ ${STACK_NAME} ]]; then
        # Do not delete a stack linked to COE cluster, handle them separatly.
        continue
    # jenkins_urls intentially needs globbing to be passed a separate params.
    elif stack_in_jenkins "$STACK_NAME" $jenkins_urls; then
        # No need to delete stacks if there exists an active build for them
        continue
    else
        echo "Deleting orphaned stack: ${STACK_NAME}"
        lftools openstack --os-cloud "${os_cloud}" stack delete --force "${STACK_NAME}"
    fi
done
