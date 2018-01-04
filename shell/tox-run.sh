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
echo "---> tox-run.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

ARCHIVE_TOX_DIR="$WORKSPACE/archives/tox"
mkdir -p "$ARCHIVE_TOX_DIR"

cd "$WORKSPACE/$TOX_DIR"

if [ ! -z "$TOX_ENVS" ]; then
    detox -e "$TOX_ENVS"  | tee -a "$ARCHIVE_TOX_DIR/detox.log"
else
    detox | tee -a "$ARCHIVE_TOX_DIR/detox.log"
fi

# Disable SC2116 as we want to echo a space separated list of TOX_ENVS
# shellcheck disable=SC2116
for i in $(echo "${TOX_ENVS//,/ }"); do
    cp -r ".tox/$i/log" "$ARCHIVE_TOX_DIR/$i"
done

echo "Completed tox runs."
