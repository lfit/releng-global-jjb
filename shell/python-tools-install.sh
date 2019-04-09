#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

set -eu -o pipefail

echo "---> python-tools-install.sh"

requirements_file=$(mktemp /tmp/requirements-XXXX.txt)

# Note: To test lftools master branch change the lftools configuration below in
#       the requirements file from "lftools[openstack]~=#.##.#" to
#       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

echo "Generating Requirements File"
cat << 'EOF' > "$requirements_file"
lftools[openstack]~=0.23.1
python-heatclient~=1.16.1
python-openstackclient~=3.16.0
dogpile.cache~=0.6.8  # Version 0.7.[01] seems to break openstackclient
niet~=1.4.2 # Extract values from yaml
EOF

# Use `python -m pip` to ensure we are using the latest version of pip
python -m pip install --user --quiet --upgrade pip
python -m pip install --user --quiet --upgrade setuptools
python -m pip install --user --quiet --upgrade -r "$requirements_file"
rm -rf $requirements_file

# Generate a list of 'pip' packages before/after
# When the 'after' list has been created, perform a diff on the two lists
echo "Listing pip packages"
pip_list_file1="/tmp/pip-list-start.txt"
pip_list_file2="/tmp/pip-list-end.txt"
if [[ -f $pip_list_file1 ]]; then
    pip list > $pip_list_file2
    echo "Compare pip packages before/after..."
    if diff --suppress-common-lines $pip_list_file1 $pip_list_file2; then
        echo "No diffs"
    fi
    rm -rf $pip_list_file1 $pip_list_file2
else
    pip list > $pip_list_file1
fi

