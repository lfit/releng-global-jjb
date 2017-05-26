#!/bin/bash
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

cd "$WORKSPACE/$TOX_DIR"
tox
