#!/bin/bash
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "$WORKSPACE/.virtualenvs/tox"
# shellcheck source=./.virtualenvs/tox/bin/activate disable=SC1091
source "$WORKSPACE/.virtualenvs/tox/bin/activate"
PYTHON="$WORKSPACE/.virtualenvs/tox/bin/python"
$PYTHON -m pip install --quiet --upgrade pip
$PYTHON -m pip install --quiet --upgrade pipdeptree
$PYTHON -m pip install --quiet --upgrade tox argparse

echo "----> Pip Dependency Tree"
pipdeptree
