#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# shellcheck disable=SC2153,SC2034
echo "---> Creating kubernetes cluster"

set -eux -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv --python python3 "cryptography<3.4" \
    "lftools[openstack]" \
    kubernetes \
    "niet~=1.4.2" \
    python-heatclient \
    python-openstackclient \
    python-magnumclient \
    setuptools \
    "openstacksdk<0.99" \
    yq

os_cloud="${OS_CLOUD:-vex}"
fixed_network="${FIXED_NETWORK}"
fixed_subnet="${FIXED_SUBNET}"
cluster_template_name="${CLUSTER_TEMPLATE_NAME}"
cluster_name="${CLUSTER_NAME}"
base_image="${BASE_IMAGE}"
keypair="${KEYPAIR}"
master_flavor="${MASTER_FLAVOR}"
node_flavor="${NODE_FLAVOR}"
master_count="${MASTER_COUNT:-1}"
node_count="${NODE_COUNT:-2}"
boot_volume_size="${BOOT_VOLUME_SIZE}"
docker_volume_size="${DOCKER_VOLUME_SIZE}"
k8s_version="${KUBERNETES_VERSION}"
cluster_settle_time="${CLUSTER_SETTLE_TIME:-1m}"


# Create the template for the cluster first. Returns the cluster ID as $template_uuid
template_uuid=$(openstack coe cluster template create "$cluster_template_name" \
    --os-cloud "$os_cloud" \
    --image "$base_image" \
    --keypair "$keypair" \
    --external-network public \
    --fixed-network "$fixed_network" \
    --fixed-subnet "$fixed_subnet" \
    --floating-ip-disabled \
    --master-flavor "$master_flavor" \
    --flavor "$node_flavor" \
    --docker-volume-size "$docker_volume_size" \
    --network-driver flannel \
    --master-lb-enabled \
    --volume-driver cinder \
    --labels \
boot_volume_type=ssd,boot_volume_size="${boot_volume_size}",\
kube_version="${k8s_version}",kube_tag="${k8s_version}" \
    --coe kubernetes \
    -f value -c uuid | tail -1)

# Create the kubernetes cluster
cluster_uuid=$(openstack coe cluster create "$cluster_name" \
    --os-cloud "$os_cloud" \
    --master-count "$master_count" \
    --node-count "$node_count" \
    --cluster-template "$template_uuid" | awk -F ' ' '{print $5}')

# Sleep for a little, because sometimes OpenStack has to catch up with itself
sleep 15

while \
[ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" \
-c status -f value)" == "CREATE_IN_PROGRESS" ]; do
    # echo "sleeping $(date)"
    sleep 2m
done

if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" \
-c status -f value)" == "CREATE_FAILED" ]; then
    echo "Failed to create cluster: $cluster_uuid $(date)"
    openstack --os-cloud "$os_cloud" coe cluster delete "$cluster_uuid"
    sleep 5m
    openstack --os-cloud "$os_cloud" coe cluster template delete "$template_uuid"
    exit 1
fi

if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" \
-c status -f value)" == "CREATE_COMPLETE" ]; then
    echo "Successfully created cluster: $cluster_uuid."
fi
