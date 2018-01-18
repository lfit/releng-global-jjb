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
# Configuration is read from $WORKSPACE/jenkins-config/clouds/openstack/$cloud/cloud.cfg
#
# Requirements: lftools must be installed to /tmp/v/lftools
# Parameters:
#     jenkins_silos:  Space separated list of Jenkins silos to push
#                     configuration to. (default: jenkins)
echo "---> jenkins-configure-clouds.sh"

#shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
source "/tmp/v/lftools/bin/activate"

GROOVY_SCRIPT_FILE="jjb/global-jjb/jenkins-admin/manage_clouds.groovy"
OS_CLOUD_DIR="$WORKSPACE/jenkins-config/clouds/openstack"
SCRIPT_DIR="$WORKSPACE/archives/groovy-inserts"
mkdir -p "$SCRIPT_DIR"

silos="${jenkins_silos:-jenkins}"

set -eu -o pipefail

get_cfg() {
    if [ -z ${3+x} ]; then
        >&2 echo "Usage: get_cfg CFG_FILE SETTING DEFAULT"
        exit 1
    fi

    local cfg_file="$1"
    local setting="$2"
    local default="$3"

    if [ ! -f "$cfg_file" ]; then
        >&2 echo "ERROR: Configuration file $cfg_file not found."
        exit 1
    fi

    cfg=$(grep "${setting^^}" "$cfg_file" | tail -1 | awk -F'=' '{print $2}')
    cfg=${cfg:-"$default"}
    echo "$cfg"
}
export get_cfg

get_cloud_cfg() {
    if [ -z $1 ]; then
        >&2 echo "Usage: get_cloud_cfg CFG_DIR"
        exit 1
    fi

    local cfg_dir="$1"
    local cfg_file="$cfg_dir/cloud.cfg"

    cloud_name=$(basename "$cfg_dir")
    cloud_url=$(get_cfg "$cfg_file" CLOUD_URL "https://auth.vexxhost.net/v3/")
    cloud_ignore_ssl=$(get_cfg "$cfg_file" CLOUD_IGNORE_SSL "false")
    cloud_zone=$(get_cfg "$cfg_file" CLOUD_ZONE "ca-ymq-1")
    cloud_credential_id=$(get_cfg "$cfg_file" CLOUD_CREDENTIAL_ID "os-cloud")

    echo "default_options = new SlaveOptions("
    get_minion_options "$cfg_file"
    echo ")"

    echo "cloud = new JCloudsCloud("
    echo "    \"$cloud_name\","
    echo "    \"$cloud_url\","
    echo "    $cloud_ignore_ssl,"
    echo "    \"$cloud_zone\","
    echo "    default_options,"
    echo "    templates,"
    echo "    \"$cloud_credential_id\""
    echo ")"
}

get_minion_options() {
    if [ -z $1 ]; then
        >&2 echo "Usage: get_minion_options CFG_FILE"
        exit 1
    fi

    local cfg_file="$1"

    image_name=$(get_cfg "$cfg_file" IMAGE_NAME "")
    hardware_id=$(get_cfg "$cfg_file" HARDWARE_ID "v1-standard-1")
    network_id=$(get_cfg "$cfg_file" NETWORK_ID "")
    user_data_id=$(get_cfg "$cfg_file" USER_DATA_ID "jenkins-init-script")
    instance_cap=$(get_cfg "$cfg_file" INSTANCE_CAP "null")
    floating_ip_pool=$(get_cfg "$cfg_file" FLOATING_IP_POOL "")
    security_groups=$(get_cfg "$cfg_file" SECURITY_GROUPS "default")
    availability_zone=$(get_cfg "$cfg_file" AVAILABILITY_ZONE "")
    start_timeout=$(get_cfg "$cfg_file" START_TIMEOUT "600000")
    key_pair_name=$(get_cfg "$cfg_file" KEY_PAIR_NAME "jenkins")
    num_executors=$(get_cfg "$cfg_file" NUM_EXECUTORS "1")
    jvm_options=$(get_cfg "$cfg_file" JVM_OPTIONS "")
    fs_root=$(get_cfg "$cfg_file" FS_ROOT "/w")
    retention_time=$(get_cfg "$cfg_file" RETENTION_TIME "0")

    echo "    new BootSource.Image(\"$image_name\"),"
    echo "    \"$hardware_id\","
    echo "    \"$network_id\","
    echo "    \"$user_data_id\","
    echo "    $instance_cap,"
    echo "    \"$floating_ip_pool\","
    echo "    \"$security_groups\","
    echo "    \"$availability_zone\","
    echo "    $start_timeout,"
    echo "    \"$key_pair_name\","
    echo "    $num_executors,"
    echo "    \"$jvm_options\","
    echo "    \"$fs_root\","
    echo "    new LauncherFactory.SSH(\"jenkins\", \"\"),"
    echo "    $retention_time"
}

get_template_cfg() {
    if [ -z $1 ]; then
        >&2 echo "Usage: get_template_cfg CFG_FILE"
        exit 1
    fi

    local cfg_file="$1"
    local minion_prefix="${2:-}"

    template_name=$(basename $cfg_file .cfg)
    labels=$(get_cfg "$cfg_file" LABELS "")

    echo "minion_options = new SlaveOptions("
    get_minion_options "$cfg_file"
    echo ")"

    echo "template = new JCloudsSlaveTemplate("
    # TODO: Figure out how to insert the "prd / snd" prefix into template name.
    echo "    \"${minion_prefix}${template_name}\","
    echo "    \"$template_name $labels\","
    echo "    minion_options,"
    echo ")"
}

mapfile -t clouds < <(ls -d1 $OS_CLOUD_DIR/*/)

for silo in $silos; do

    script_file="$SCRIPT_DIR/${silo}-cloud-cfg.groovy"
    cp "$GROOVY_SCRIPT_FILE" "$script_file"

    # Linux Foundation Jenkins systems use "prd-" and "snd-" to mark
    # production and sandbox servers.
    if [ "$silo" == "releng" ] || [ "$silo" == "production" ]; then
        node_prefix="prd-"
    elif [ "$silo" == "sandbox" ]; then
        node_prefix="snd-"
    else
        node_prefix="${silo}-"
    fi

    echo "-----> Groovy script $script_file"
    for cloud in "${clouds[@]}"; do
        cfg_dir="${cloud}"
        insert_file="$SCRIPT_DIR/$cloud/cloud-cfg.txt"
        echo "Processing $cfg_dir"
        mkdir -p "$SCRIPT_DIR/$cloud"
        rm -f "$insert_file"

        echo "" >> "$insert_file"
        echo "//////////////////////////////////////////////////" >> "$insert_file"
        echo "// Cloud config for $(basename $cloud)" >> "$insert_file"
        echo "//////////////////////////////////////////////////" >> "$insert_file"
        echo "" >> "$insert_file"

        echo "templates = []" >> $insert_file
        mapfile -t templates < <(find $cfg_dir -maxdepth 1 -not -type d -not -name "cloud.cfg")
        for template in "${templates[@]}"; do
            get_template_cfg "$template" "$node_prefix" >> "$insert_file"
            echo "templates.add(template)" >> "$insert_file"
        done

        get_cloud_cfg "$cfg_dir" >> "$insert_file"
        echo "clouds.add(cloud)" >> "$insert_file"

        cat "$insert_file" >> "$script_file"
    done

    set +x  # Ensure that no other scripts add `set -x` and print passwords
    echo "Configuring $silo"
    JENKINS_URL=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" url)
    JENKINS_USER=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" user)
    JENKINS_PASSWORD=$(crudini --get "$HOME"/.config/jenkins_jobs/jenkins_jobs.ini "$silo" password)
    export JENKINS_URL
    export JENKINS_USER
    export JENKINS_PASSWORD

    lftools jenkins groovy "$script_file"
done
