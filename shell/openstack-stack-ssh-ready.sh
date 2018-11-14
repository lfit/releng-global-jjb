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

echo "----------> Copy ssh public keys to csit lab"

function copy-ssh-keys-to-slave() {
    RETRIES=60
    for j in $(seq 1 $RETRIES); do
        # shellcheck disable=SC2006,SC2092
        if `ssh-copy-id -i /home/jenkins/.ssh/id_rsa.pub "jenkins@${i}" > /dev/null 2>&1`; then
            ssh "jenkins@${i}" 'echo "$(facter ipaddress_eth0) $(/bin/hostname)" | sudo tee -a /etc/hosts'
            echo "Successfully copied public keys to slave ${i}"
            break
        elif [ "$j" -eq $RETRIES ]; then
            echo "SSH not responding on ${i} after $RETIRES tries. Giving up."

            server=$(openstack port list -f value -c device_id --fixed-ip ip-address="${i}")
            echo "Dumping console logs for $server ${i}"
            openstack console log show "$server"

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

# Print the Stack outputs parameters so that we can identify which IPs belong
# to which VM types.
openstack stack show -c outputs "$STACK_NAME"

# shellcheck disable=SC2006,SC2207
ADDR=(`openstack stack show -f json -c outputs "$STACK_NAME" | \
       jq -r '.outputs[] | \
              select(.output_key | match("^vm_[0-9]+_ips\$")) | \
              .output_value | .[]'`)
pids=""
for i in "${ADDR[@]}"; do
    ( copy-ssh-keys-to-slave ) &
    # Store PID of process
    pids+=" $!"
done

# Detect when a process failed to copy ssh keys and fail build
for p in $pids; do
    if wait "$p"; then
        echo "Process $p successfully copied ssh keys."
    else
        echo "Process $p failed to copy ssh keys."
        exit 1
    fi
done
echo "Copying ssh keys complete."
