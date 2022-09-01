#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017, 2022 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Scans OpenStack for orphaned COE clusters
echo "---> Orphaned k8s clusters"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

cluster_in_jenkins() {
    # Usage: cluster_in_jenkins CLUSTER_NAME JENKINS_URL [JENKINS_URL...]
    # Returns: 0 If CLUSTER_NAME is in Jenkins and 1 if CLUSTER_NAME is not
    # in Jenkins.

    CLUSTER_NAME="${1}"

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

    if [[ "${builds[*]}" =~ $CLUSTER_NAME ]]; then
        return 0
    fi

    return 1
}

# shellcheck disable=SC1090
source ~/lf-env.sh
# Check if openstack venv was previously created
if [ -f "/tmp/.os_lf_venv" ]; then
    os_lf_venv=$(cat "/tmp/.os_lf_venv")
fi

if [ -d "${os_lf_venv}" ] && [ -f "${os_lf_venv}/bin/openstack" ]; then
    echo "Re-use existing venv: ${os_lf_venv}"
    PATH=$os_lf_venv/bin:$PATH
else
    lf-activate-venv --python python3 \
        kubernetes \
        python-heatclient \
        python-openstackclient \
        python-magnumclient
fi

#########################
## FETCH ACTIVE BUILDS ##
#########################
# Fetch coe cluster list before fetching active stacks.
mapfile -t OS_COE_CLUSTERS < <(openstack --os-cloud "$os_cloud" coe cluster list \
            -f value -c "uuid" -c "name" -c "status" -c "health_status" \
            | awk '{print $2}')

##########################
## DELETE UNUSED STACKS ##
##########################
echo "-----> Delete orphaned cluster"

# Search for COE clusters not in use by any active Jenkins systems and remove them.
for CLUSTER_NAME in "${OS_COE_CLUSTERS[@]}"; do
    # jenkins_urls intentially needs globbing to be passed a separate params.
    # shellcheck disable=SC2153,SC2086
    if cluster_in_jenkins "$CLUSTER_NAME" $jenkins_urls; then
        # No need to delete stacks if there exists an active build for them
        continue
    else
        echo "Deleting orphaned k8s cluster: $CLUSTER_NAME"
        openstack --os-cloud "$os_cloud" coe cluster delete "$CLUSTER_NAME"
    fi
done
