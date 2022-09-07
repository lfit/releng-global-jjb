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
echo "---> Copy SSH public keys to CSIT lab"

os_cloud="${OS_CLOUD:-vex}"
stack_name="${OS_STACK_NAME}"

copy_ssh_keys () {
    if [ -z "$1" ]; then
        >&2 echo "ERROR: Missing required arguments."
        >&2 echo "Usage: copy_ssh_keys IP_ADDRESS"
        exit 1
    fi

    local ip_address="$1"
    RETRIES=60

    for i in $(seq 1 $RETRIES); do
        if ssh-copy-id -i /home/jenkins/.ssh/id_rsa.pub "jenkins@${ip_address}" > /dev/null 2>&1; then
            ssh "jenkins@${ip_address}" 'echo "$(facter ipaddress_eth0) $(/bin/hostname)" | sudo tee -a /etc/hosts'
            echo "Successfully copied public keys to slave ${ip_address}"
            break
        elif [ "$i" -eq $RETRIES ]; then
            echo "SSH not responding on ${ip_address} after $RETIRES tries. Giving up."

            server=$(openstack port list -f value -c device_id --fixed-ip ip-address="${ip_address}")
            echo "Dumping console logs for $server ${ip_address}"
            openstack --os-cloud "$os_cloud" console log show "$server"

            exit 1
        else
            echo "SSH not responding on ${ip_address}. Retrying in 10 seconds..."
            sleep 10
        fi

        # ping test to see if connectivity is available
        if ping -c1 "${ip_address}" &> /dev/null; then
            echo "Ping to ${ip_address} successful."
        else
            echo "Ping to ${ip_address} failed."
        fi
    done
}

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "lftools[openstack]" \
    kubernetes \
    python-heatclient \
    python-openstackclient

# IP Addresses are returned as a space separated list so word splitting is ok
# shellcheck disable=SC2207
ip_addresses=($(openstack --os-cloud "$os_cloud" stack show -f json -c outputs "$stack_name" |
        jq -r '.outputs[] |
                select(.output_key | match("^vm_[0-9]+_ips$")) |
                .output_value | .[]'))
pids=""
for ip in "${ip_addresses[@]}"; do
    ( copy_ssh_keys "$ip" ) &
    # Store PID of process
    pids+=" $!"
done
for p in $pids; do
    if wait "$p"; then
        echo "Process $p ready."
    else
        echo "Process $p timed out waiting for SSH."
        exit 1
    fi
done
echo "SSH ready on all stack servers."
