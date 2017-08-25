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

if [ -z "$TOX_ENVS" ]; then
    TOX_ENVS=$(crudini --get tox.ini tox envlist)
fi

TOX_ENVS=(${TOX_ENVS//,/ })
for i in "${TOX_ENVS[@]}"; do
    echo ""
    echo "-----> Running tox $i"
    tox -e "$i" | tee -a "$ARCHIVE_TOX_DIR/tox-$i.log"
done
