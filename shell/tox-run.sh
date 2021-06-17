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

# do not use -o pipefail
set -eux

#Ensure that tox from tox-install.sh takes precedence.
PATH=$HOME/.local/bin:$PATH

ARCHIVE_TOX_DIR="$WORKSPACE/archives/tox"
ARCHIVE_DOC_DIR="$WORKSPACE/archives/docs"
mkdir -p "$ARCHIVE_TOX_DIR"
cd "$WORKSPACE/$TOX_DIR" || exit 1

if [[ -d /opt/pyenv ]]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    PYTHONPATH="$(pwd)"
    export PYTHONPATH
    export TOX_TESTENV_PASSENV=PYTHONPATH
fi

#Useful debug
tox --version

PARALLEL="${PARALLEL:-true}"
TOX_OPTIONS_LIST=""

if [[ -n ${TOX_ENVS:-} ]]; then
    TOX_OPTIONS_LIST=$TOX_OPTIONS_LIST" -e $TOX_ENVS"
fi;

if [[ ${PARALLEL,,} = true ]]; then
    TOX_OPTIONS_LIST=$TOX_OPTIONS_LIST" --parallel auto --parallel-live"
fi;

# $TOX_OPTIONS_LIST are intentionnaly not surrounded by quotes
# to correcly pass options to tox
# shellcheck disable=SC2086
tox $TOX_OPTIONS_LIST | tee -a "$ARCHIVE_TOX_DIR/tox.log"
tox_status="${PIPESTATUS[0]}"

echo "---> Completed tox runs"

# Disable SC2116 as we want to echo a space separated list of TOX_ENVS
# shellcheck disable=SC2116
for i in .tox/*/log; do
    tox_env=$(echo "$i" | awk -F'/' '{print $2}')
    # defend against glob finding no matches
    if ! cp -r "$i" "$ARCHIVE_TOX_DIR/$tox_env"; then
        echo "WARN: no logs found to archive"
        break
    fi
done

# If docs are generated push them to archives.
DOC_DIR="${DOC_DIR:-docs/_build/html}"
if [[ -d $DOC_DIR ]]; then
    echo "---> Archiving generated docs"
    mv "$DOC_DIR" "$ARCHIVE_DOC_DIR"
fi

echo "---> tox-run.sh ends"

test "$tox_status" -eq 0 || exit "$tox_status"
