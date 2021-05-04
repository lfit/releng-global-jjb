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
echo "---> npm-config.sh"

# Configure a custom hosted npm registry and / or https://registry.npmjs.org/

# $NPM_REGISTRY : Required
#                 Jenkins global variable should be defined
#                 If set, then this is the base IP or FQDN that will be used
#                 for logging into the custom npm registry
#                 ex: $NPM_URL/repository/npm.snapshot/
#                 wereh NPM_URL is defined as a global env var in Jenkins.
# $NPM_SERVER_ID: Required
#                 The id of the server as specified in the global-settings file
#                 Typically this is settings.xml
# $SETTINGS_FILE: Required
#                 Job level variable with maven settings file location
#

# Ensure we fail the job if any steps fail
set -eu -o pipefail

# Execute the credential lookup and login to the registry
do_config() {
    echo "$1"
    CREDENTIAL=$(xmlstarlet sel -N "x=http://maven.apache.org/SETTINGS/1.0.0" \
        -t -m "/x:settings/x:servers/x:server[starts-with(x:id, '${NPM_SERVER_ID}')]" \
        -v x:username -o ":" -v x:password \
        "$SETTINGS_FILE")

    USER=$(echo "$CREDENTIAL" | cut -f1 -d:)
    PASS=$(echo "$CREDENTIAL" | cut -f2 -d:)

    if [ -z "$USER" ]; then
        echo "ERROR: No user provided"
        return 1
    fi

    if [ -z "$PASS" ]; then
        echo "ERROR: No password provided"
        return 1
    fi

    # Compute auth token
    auth_token=$(echo -n "$USER":"$PASS" | openssl base64)

    # Write .npmrc
    echo "//$NPM_REGISTRY:_auth$auth_token" >> "$HOME/.npmrc"
}
