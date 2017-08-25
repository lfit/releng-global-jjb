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

run_tox() {
    local log_dir="$1"
    local env="$2"

    echo "-----> Running tox $env"
    if ! tox -e $env > "$log_dir/tox-$env.log"; then
        echo "$env" >> "$log_dir/failed-envs.log"
    fi
}

TOX_ENVS=(${TOX_ENVS//,/ })
if hash parallel 2>/dev/null; then
    export -f run_tox
    parallel --jobs 200% "run_tox $ARCHIVE_TOX_DIR {}" ::: ${TOX_ENVS[*]}
else
    for env in "${TOX_ENVS[@]}"; do
        run_tox "$env"
    done
fi

if [ -f "$ARCHIVE_TOX_DIR/failed-envs.log" ]; then
    failed_envs=($(cat "$ARCHIVE_TOX_DIR/failed-envs.log"))
    echo "ERROR: Failed the following builds: ${failed_envs[*]}"
    exit 1
fi

echo "Completed tox runs."
