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
echo "---> tox-run.sh"

ARCHIVE_TOX_DIR="$WORKSPACE/archives/tox"
ARCHIVE_DOC_DIR="$WORKSPACE/archives/docs"
mkdir -p "$ARCHIVE_TOX_DIR"
cd "$WORKSPACE/$TOX_DIR" || exit 1

if [ -d "/opt/pyenv" ]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    PYTHONPATH="$(pwd)"
    export PYTHONPATH
    export TOX_TESTENV_PASSENV=PYTHONPATH
fi

PARALLEL="${PARALLEL:-true}"
if [ "${PARALLEL}" = true ]; then
    if [ -n "$TOX_ENVS" ]; then
        tox -e "$TOX_ENVS" --parallel auto --parallel-live | tee -a "$ARCHIVE_TOX_DIR/tox.log"
        tox_status="${PIPESTATUS[0]}"
    else
        tox --parallel auto --parallel-live | tee -a "$ARCHIVE_TOX_DIR/tox.log"
        tox_status="${PIPESTATUS[0]}"
    fi
else
    if [ -n "$TOX_ENVS" ]; then
        tox -e "$TOX_ENVS" | tee -a "$ARCHIVE_TOX_DIR/tox.log"
        tox_status="${PIPESTATUS[0]}"
    else
        tox | tee -a "$ARCHIVE_TOX_DIR/tox.log"
        tox_status="${PIPESTATUS[0]}"
    fi
fi

# Disable SC2116 as we want to echo a space separated list of TOX_ENVS
# shellcheck disable=SC2116
for i in .tox/*/log; do
    tox_env=$(echo "$i" | awk -F'/' '{print $2}')
    cp -r "$i" "$ARCHIVE_TOX_DIR/$tox_env"
done

echo "Completed tox runs."


# If docs are generated push them to archives.
DOC_DIR="${DOC_DIR:-docs/_build/html}"
if [[ -d "$DOC_DIR" ]]; then
    echo "---> Archiving generated docs"
    mv "$DOC_DIR" "$ARCHIVE_DOC_DIR"
fi

test "$tox_status" -eq 0 || exit "$tox_status"
