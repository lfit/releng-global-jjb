#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This file contains a list of variables that are generally useful in many
# scripts. It is meant to be sourced in other scripts so that the variables can
# be called.

MAVEN_OPTIONS="$(echo --show-version \
    --batch-mode \
    -Djenkins \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
    -Dmaven.repo.local=/tmp/r \
    -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r)"
echo "$MAVEN_OPTIONS"

# Activates the lftools virtualenv
lftools_activate() {
    virtualenv --quiet "/tmp/v/lftools"
    set +u  # Ignore unbound variables in activate
    # shellcheck source=/tmp/v/lftools/bin/activate disable=SC1091
    source "/tmp/v/lftools/bin/activate"
    set -u  # Restore unbound variable checking
}
