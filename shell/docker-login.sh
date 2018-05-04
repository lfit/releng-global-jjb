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

# Log into a custom hosted docker registry and / or docker.io

# $DOCKER_REGISTRY : Optional
#                    Jenkins global variable should be defined
#                    If set, then this is the base IP or FQDN that will be used
#                    for logging into the custom docker registry
#                    ex: nexus3.example.com
#
# $REGISTRY_PORTS  : Required if DOCKER_REGISTRY is set
#                    Jenkins global variable should be defined (space separated)
#                    Listing of all the registry ports to login to
#                    ex: 10001 10002 10003 10004
#
# $DOCKERHUB_REGISTRY: Optional
#                      Set global Jenkins variable to `docker.io`
#                      Additionally you will need to add as an entry
#                      to your projects mvn-settings file with username
#                      and password creds.  If you are using docker version
#                      < 17.06.0 you will need to set DOCKERHUB_EMAIL
#                      to auth to docker.io.
#
# $SETTINGS_FILE   : Job level variable with maven settings file location
#
# $DOCKERHUB_EMAIL : Optional
#                    Jenkins global variable that defines the email address that
#                    should be used for logging into DockerHub
#                    Note that this is required if you are using
#                    docker version < 17.06.0.

# Ensure we fail the job if any steps fail
set -eu -o pipefail

# Determine the need for email flag based on docker version
need_email() {
    docker_version=$(docker -v | awk '{print $3}')
    compare_value=$(echo "17.06.0 $docker_version" | \
                    tr " " "\n" | \
                    sort -V | \
                    sed -n 1p)
    if [[ "$docker_version" == "$compare_value" && \
          "$docker_version" != "17.06.0" && \
          "$DOCKERHUB_REGISTRY" == "docker.io" ]]
   then
       return true
    fi
    return false
}

# Execute the credential lookup and set
set_creds() {
    set +x  # Ensure that no other scripts add `set -x` and print passwords
    echo "$1"
    CREDENTIAL=$(xmlstarlet sel -N "x=http://maven.apache.org/SETTINGS/1.0.0" \
        -t -m "/x:settings/x:servers/x:server[starts-with(x:id, '${1}')]" \
        -v x:username -o ":" -v x:password \
        "$SETTINGS_FILE")

    USER=$(echo "$CREDENTIAL" | cut -f1 -d:)
    PASS=$(echo "$CREDENTIAL" | cut -f2 -d:)

    if [ -z "$USER" ]
    then
        echo "ERROR: No user provided"
        return 1
    fi

    if [ -z "$PASS" ]
    then
        echo "ERROR: No password provided"
        return 1
    fi
 
}
# Login to the registry
do_login() {
    if [ "${DOCKERHUB_EMAIL:-none}" != 'none' ]
    then
        docker login -u "$USER" -p "$PASS" -e "$2" "$1"
    else
        docker login -u "$USER" -p "$PASS" "$1"
    fi
}

# Loop through Registry and Ports to concatentate and login to nexus
if [ "${DOCKER_REGISTRY:-none}" != 'none' ]
then
    for PORT in $REGISTRY_PORTS
    do
        REGISTRY="${DOCKER_REGISTRY}:${PORT}"

        # docker login requests an email address if nothing is passed to it
        # Nexus, however, does not need this and ignores the value
        do_login "$REGISTRY" none
    done
fi

# Login to docker.io after determining if email is needed.
if [ "${DOCKERHUB_REGISTRY:-none}" != 'none' ]
then
    if need_email()
    then
        do_login "$DOCKERHUB_REGISTRY" "$DOCKERHUB_EMAIL"
    else
        do_login "$DOCKERHUB_REGISTRY" none
fi
