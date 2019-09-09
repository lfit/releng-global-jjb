#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> logs-deploy.sh"

set -eu -o pipefail -o noglob

# Add 'lftools' to PATH
PATH=$PATH:~/.local/bin

if [[ -z ${LOGS_SERVER:-} ]]; then
    echo "WARNING: Logging server not set: Nothing to do"
else
    nexus_url="${NEXUSPROXY:-$NEXUS_URL}"
    nexus_path="$SILO/$JENKINS_HOSTNAME/$JOB_NAME/$BUILD_NUMBER"

    echo "Archiving 'sudo' log.."
    os=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')
    case $os in
        fedora|centos|redhat) sudo_log=/var/log/secure   ;;
        ubuntu)               sudo_log=/var/log/auth.log ;;
        *)  echo "Unexpected 'operatingsystem': $os"
            echo "Unable to archive 'sudo' logs"
            exit
            ;;
    esac
    if ! sudo cp $sudo_log /tmp; then
        echo "Unable to archive 'sudo' logs ($sudo_log)"
    else
        sudo_log=$(basename $sudo_log)
        sudo chown jenkins:jenkins /tmp/$sudo_log
        chmod 0644 /tmp/$sudo_log
        mkdir $WORKSPACE/archives/sudo
        mv /tmp/$sudo_log $WORKSPACE/archives/sudo/$sudo_log
    fi

    # Convert multiple search extensions to list of arguments'
    # "ext1 ext2" -> "-p ext1 -p ext2"
    pattern_opts=""
    for i in ${ARCHIVE_ARTIFACTS:-}; do
        pattern_opts+="-p $i "
    done

    # Add 'python env' to PATH
    PATH=~/.local/bin:$PATH
    lftools deploy archives $pattern_opts $nexus_url $nexus_path $WORKSPACE
    lftools deploy logs $nexus_url $nexus_path $BUILD_URL

    echo "Build logs: <a href='$LOGS_SERVER/$nexus_path' > $LOGS_SERVER/$nexus_path</a>"
fi
