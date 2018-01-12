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

if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

set +e  # Allow detox to fail so that we can collect the logs in the next step
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
set -e  # Logs collected so re-enable

echo "Completed tox runs."
