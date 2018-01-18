#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
# Pulls global variable definitions out of a file.
#
# Configuration is read from $WORKSPACE/jenkins-config/global-vars-$silo.sh
#
# Requirements: lftools must be installed to /tmp/v/lftools
# Parameters:
#     jenkins_silos:  Space separated list of Jenkins silos to push global-vars
#                     configuration to. (default: jenkins)
echo "---> jenkins-configure-global-vars.sh"

get_cloud_cfg() {
    local cfg_file="$1"
    local setting="$2"
    local default="$3"
    cfg=$(grep "${1^^}" "$default_options" | tail -1 | awk -F'=' '{print $2}')
    cfg=${cfg:-"$default"}
    echo "$cfg"
}
export get_cloud_cfg

#GROOVY_SCRIPT_FILE="jjb/global-jjb/jenkins-admin/manage_clouds.groovy"
GROOVY_SCRIPT_FILE="jenkins-admin/manage_clouds.groovy"
WORKSPACE=/tmp

# shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
# source "/tmp/v/lftools/bin/activate"
silos="${jenkins_silos:-jenkins}"
#
# set -eu -o pipefail

default_options="$WORKSPACE/jenkins-config/clouds/openstack/default.sh"

if [ ! -f "$default_options" ]; then
    echo "ERROR: Configuration file $default_options not found."
    exit 1
fi

hardware_id=$(get_cloud_cfg "$default_options" HARDWARE_ID "v1-standard-1")
fs_root=$(get_cloud_cfg "$default_options" FS_ROOT "/w")

{
    echo "    \"$hardware_id\","
    echo "    \"$network_id\","
    echo "    \"$user_data_id\","
    echo "    \"$instance_cap\","
    echo "    \"$floating_ip_pool\","
    echo "    \"$security_groups\","
    echo "    \"$availability_zone\","
    echo "    \"$start_timeout\","
    echo "    \"$key_pair_name\","
    echo "    \"$num_executors\","
    echo "    \"$jvm_options\","
    echo "    \"$fs_root\","
    echo "    \"$launcher_factory\","
    echo "    \"$retention_time\","
} > insert.txt

echo "-----> script.groovy"
sed "/DEFAULT_OPTIONS/r insert.txt" "$GROOVY_SCRIPT_FILE" \
    | sed "0,/DEFAULT_OPTIONS/{/DEFAULT_OPTIONS/d}" \
    > script.groovy
cat script.groovy

# for silo in $silos; do
#     set +x  # Ensure that no other scripts add `set -x` and print passwords
#     echo "Configuring $silo"
#
#     JENKINS_URL=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" url)
#     JENKINS_USER=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" user)
#     JENKINS_PASSWORD=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" password)
#     export JENKINS_URL
#     export JENKINS_USER
#     export JENKINS_PASSWORD
#
#     lftools jenkins groovy script.groovy
# done
