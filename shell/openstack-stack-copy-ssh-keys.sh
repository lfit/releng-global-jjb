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

function copy_ssh_keys() {
    RETRIES=60

    for j in $(seq 1 $RETRIES); do
        if ssh-copy-id -i /home/jenkins/.ssh/id_rsa.pub "jenkins@${i}" > /dev/null 2>&1; then
            ssh "jenkins@${i}" 'echo "$(facter ipaddress_eth0) $(/bin/hostname)" | sudo tee -a /etc/hosts'
            echo "Successfully copied public keys to slave ${i}"
            break
        elif [ "$j" -eq $RETRIES ]; then
            echo "SSH not responding on ${i} after $RETIRES tries. Giving up."

            server=$(openstack port list -f value -c device_id --fixed-ip ip-address="${i}")
            echo "Dumping console logs for $server ${i}"
            openstack --os-cloud "$os_cloud" console log show "$server"

            exit 1
        else
            echo "SSH not responding on ${i}. Retrying in 10 seconds..."
            sleep 10
        fi

        # ping test to see if connectivity is available
        if ping -c1 "${i}" &> /dev/null; then
            echo "Ping to ${i} successful."
        else
            echo "Ping to ${i} failed."
        fi
    done
}

# IP Addresses are returned as a space separated list so word splitting is ok
# shellcheck disable=SC2207
ip_addresses=($(openstack --os-cloud "$os_cloud" stack show -f json -c outputs "$stack_name" |
       jq -r '.outputs[] |
              select(.output_key | match("^vm_[0-9]+_ips$")) |
              .output_value | .[]'))
pids=""
for i in "${ip_addresses[@]}"; do
    ( copy_ssh_keys ) &
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
