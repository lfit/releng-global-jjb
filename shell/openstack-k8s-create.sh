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
echo "---> Creating kubernetes cluster"

#os_cloud="${OS_CLOUD:-vex}"
#cluster_name="${CLUSTER_NAME}"
#base_image="${BASE_IMAGE}" # "Fedora Atomic 29 [2019-08-20]"
#keypair="${OS_KEYPAIR}"  # dwt2-key
#master_flavor="${MASTER_FLAVOR}"  # v2-standard-1
#node_flavor="${NODE_FLAVOR}"  # v2-highcpu-8
#volume_size="${VOLUME_SIZE}"  # in GB, 50
#k8s_version="${KUBERNETES_VERSION}"  # v1.16.0

os_cloud="ecompci"
fixed_network="ecompci"
fixed_subnet="ecompci-subnet1"
cluster_template_name="my_cluster_template_name"
cluster_name="my_cluster_name"
base_image="Fedora Atomic 29 [2019-08-20]" # "Fedora Atomic 29 [2019-08-20]"
keypair="dwt2-key"  # dwt2-key
master_flavor="v2-standard-1"  # v2-standard-1
node_flavor="v2-highcpu-8"  # v2-highcpu-8
master_count="1"
node_count="2"
boot_volume_size="8"  # in GB, 50
docker_volume_size="50"  # in GB, 50
k8s_version="v1.16.0"  # v1.16.0
cluster_settle_time="${CLUSTER_SETTLE_TIME:1m}"


#set -eux -o pipefail
#echo "**********\Current resoure allocation is: "
#echo "openstack --os-cloud "$os_cloud" limits show --absolute"
#echo "End current resource allocation\n**********"

# Create the template for the cluster first. Returns the cluster ID in $template_uuid
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
  --labels boot_volume_type=ssd,boot_volume_size="${boot_volume_size}",kube_version="${k8s_version}",kube_tag="${k8s_version}" \
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

while [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c status -f value)" == "CREATE_IN_PROGRESS" ]
do
  echo "sleeping $(date)"
  sleep 30
done

if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c status -f value)" == "CREATE_FAILED" ]
then
  echo "Failed to create cluster: $cluster_uuid $(date)"
  exit 1
fi

if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c status -f value)" == "CREATE_COMPLETE" ]
then
  echo "Successfully created cluster: $cluster_uuid. Checking cluster health."
fi

# Ensure the state of the cluster is healthy
if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c health_status -f value)" != "HEALTHY" ]
then
  echo "Cluster $cluster_uuid is reporting as UNHEALTHY, allowing one more minute to settle"
  sleep "$cluster_settle_time"

  if [ "$(openstack --os-cloud "$os_cloud" coe cluster show "$cluster_uuid" -c health_status -f value)" == "HEALTHY" ]
  then
    echo "Cluster $cluster_uuid has settled and is now healthy"
    exit 0
  else
    echo "Cluster $cluster_uuid failed to reach a healthy state, failing the build and cleaning up"
    openstack --os-cloud "$os_cloud" coe cluster delete "$cluster_uuid"
    openstack --os-cloud "$os_cloud" coe cluster template delete "$template_uuid"
    exit 1
  fi

fi