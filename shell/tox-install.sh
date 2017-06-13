#!/bin/bash
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet "/tmp/v/tox"
# shellcheck source=/tmp/v/tox/bin/activate disable=SC1091
source "/tmp/v/tox/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade pipdeptree
pip install --quiet --upgrade tox argparse

echo "----> Pip Dependency Tree"
pipdeptree
