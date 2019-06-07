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
echo "---> python-tools-install.sh"

set -eu -o pipefail

# Generate a list of 'pip' packages pre-build/post-build
# During post-build, perform a diff on the two lists and copy files to archive directory
echo "Listing pip packages"
pip_list_pre=/tmp/pip-list-pre.txt
pip_list_post=/tmp/pip-list-post.txt
pip_list_diffs=/tmp/pip-list-diffs.txt
if [[ -f $pip_list_pre ]]; then
    pip list > $pip_list_post
    echo "Compare pip packages before/after..."
    if diff --suppress-common-lines $pip_list_pre $pip_list_post \
            | tee $pip_list_diffs; then
        echo "No diffs" | tee $pip_list_diffs
    fi
    mkdir -p $WORKSPACE/archives
    cp $pip_list_pre $pip_list_post $pip_list_diffs $WORKSPACE/archives
    rm -rf $pip_list_pre $pip_list_post $pip_list_diffs
    ls $WORKSPACE/archives
    # Would just like to 'exit 0' here but we can't because the
    # log-deploy.sh script is 'appended' to this file and it would not
    # be executed.
else
    pip list > $pip_list_pre
    # These 'pip installs' only need to be executed during pre-build

    requirements_file=$(mktemp /tmp/requirements-XXXX.txt)

    # Note: To test lftools master branch change the lftools configuration below in
    #       the requirements file from "lftools[openstack]~=#.##.#" to
    #       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

    echo "Generating Requirements File"
    cat << 'EOF' > "$requirements_file"
lftools[openstack]~=0.24.0
python-heatclient~=1.16.1
python-openstackclient~=3.16.0
dogpile.cache~=0.6.8  # Version 0.7.[01] seems to break openstackclient
niet~=1.4.2 # Extract values from yaml
yq~=2.7.2
EOF

    # Use `python -m pip` to ensure we are using the latest version of pip
    python -m pip install --user --quiet --upgrade pip
    python -m pip install --user --quiet --upgrade setuptools
    python -m pip install --user --quiet --upgrade -r "$requirements_file"
    rm -rf $requirements_file
fi
