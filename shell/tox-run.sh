#!/bin/bash
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

cd "$WORKSPACE/$TOX_DIR"

if [ -n "$TOX_ENVS" ];
then
    tox -e "$TOX_ENVS"
else
    tox
fi
