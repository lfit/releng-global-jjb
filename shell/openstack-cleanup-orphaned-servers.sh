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
# Scans OpenStack for orphaned servers
echo "---> Orphaned servers"

os_cloud="${OS_CLOUD:-vex}"
jenkins_urls="${JENKINS_URLS:-}"

minion_in_jenkins() {
    # Usage: minion_in_jenkins STACK_NAME JENKINS_URL [JENKINS_URL...]
    # Returns: 0 If stack is in Jenkins and 1 if stack is not in Jenkins.

    MINION="${1}"

    minions=()
    for jenkins in "${@:2}"; do
        JENKINS_URL="$jenkins/computer/api/json?tree=computer[displayName]"
        resp=$(curl -s -w "\\n\\n%{http_code}" --globoff -H "Content-Type:application/json" "$JENKINS_URL")
        json_data=$(echo "$resp" | head -n1)
        status=$(echo "$resp" | awk 'END {print $NF}')

        if [ "$status" != 200 ]; then
            >&2 echo "ERROR: Failed to fetch data from $JENKINS_URL with status code $status"
            >&2 echo "$resp"
            exit 1
        fi

        # We purposely want to wordsplit here to combine the arrays
        # shellcheck disable=SC2206,SC2207
        minions=(${minions[@]} $(echo "$json_data" | \
            jq -r '.computer[].displayName' | grep -v master)
        )
    done

    if [[ "${minions[*]}" =~ $MINION ]]; then
        return 0
    fi

    return 1
}

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "lftools[openstack]" \
    kubernetes \
    python-heatclient \
    python-openstackclient \
    python-magnumclient

##########################
## FETCH ACTIVE MINIONS ##
##########################
# Fetch server list before fetching active minions to minimize race condition
# where we might be trying to delete servers while jobs are trying to start

mapfile -t OS_SERVERS < <(openstack --os-cloud "$os_cloud" server list -f value -c "Name" | grep -E 'prd|snd')

echo "-----> Active servers"
for server in "${OS_SERVERS[@]}"; do
    echo "$server"
done


#############################
## DELETE ORPHANED SERVERS ##
#############################
echo "-----> Delete orphaned servers"

# Search for servers not in use by any active Jenkins systems and remove them.
for server in "${OS_SERVERS[@]}"; do
    # jenkins_urls intentially needs globbing to be passed a separate params.
    # needs to be globbed.
    # shellcheck disable=SC2153,SC2086
    if minion_in_jenkins "$server" $jenkins_urls; then
        # No need to delete server if it is still attached to Jenkins
        continue
    else
        echo "Deleting orphaned server: $server"
        lftools openstack --os-cloud "$os_cloud" \
            server remove --minutes 15 "$server"
    fi
done
