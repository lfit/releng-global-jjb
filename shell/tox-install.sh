#!/bin/bash
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv "$WORKSPACE/.virtualenvs/tox"
# shellcheck source=./.virtualenvs/tox/bin/activate disable=SC1091
source "$WORKSPACE/.virtualenvs/tox/bin/activate"
PYTHON="$WORKSPACE/.virtualenvs/tox/bin/python"
$PYTHON -m pip install --upgrade pip
$PYTHON -m pip install --upgrade tox argparse
$PYTHON -m pip freeze
cd "$WORKSPACE/repo/$TOX_DIR"
tox
