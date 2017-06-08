#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This script publishes artifacts to a staging repo in Nexus.
#
# This script expects the directory $WORKSPACE/m2repo to exist and uses that to
# deploy the staging repository.
#
# This script expects the $NEXUS_URL Jenkins global variable to exist.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

rsync -avz --exclude 'maven-metadata*' \
           --exclude '_remote.repositories' \
           --exclude 'resolver-status.properties' \
           "$WORKSPACE/m2repo/" "$WORKSPACE/stage.repo"

# Disable SC2086 because we want to allow word splitting for $MAVEN_* parameters.
# shellcheck disable=SC2086
$MVN org.sonatype.plugins:nexus-staging-maven-plugin:1.6.8:deploy-staged-repository \
    -DrepositoryDirectory="$WORKSPACE/stage.repo/" \
    -DnexusUrl="$NEXUS_URL" \
    -DstagingProfileId="$STAGING_PROFILE_ID" \
    -DserverId="opendaylight-staging" \
    --global-settings "$GLOBAL_SETTINGS_FILE" \
    --settings "$SETTINGS_FILE" \
    $MAVEN_OPTIONS | tee /tmp/stage-repo.log

grep Closing /tmp/stage-repo.log \
    | awk -F'"' '{print $2}' > "$WORKSPACE/archive/staging-repo-id"
