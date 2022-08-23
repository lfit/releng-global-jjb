#!/bin/bash
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

set -eufo pipefail

# Override the python version from pyenv installs to be used as default
python="python3"
if [[ -d /opt/pyenv ]]; then
    echo "---> Setting up pyenv"
    export PYENV_ROOT="/opt/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    pyenv versions
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init - --no-rehash)"
        pyenv local $(lf-pyver "$python")
    fi
fi

# This script will typically be called during pre-build & post-build.
# Create the user venv during pre-build.
if [[ ! -f /tmp/pre-build-complete ]]; then
    requirements_file=$(mktemp /tmp/requirements-XXXXXX)

    # Note: To test lftools master branch change the lftools configuration below in
    #       the requirements file from "lftools[openstack]~=#.##.#" to
    #       git+https://github.com/lfit/releng-lftools.git#egg=lftools[openstack]

    echo "Generating Requirements File"
    cat << 'EOF' > "$requirements_file"
openstacksdk<0.99
python-heatclient
python-openstackclient
python-magnumclient
kubernetes
niet~=1.4.2
cryptography<3.4
yq

# PINNED INDIRECT DEPENDENCIES
# ============================
# The libraries listed below should be considered workarounds and thus need
# to have a link to a JIRA and any relevant pkg versions and support packages
# necessary so that future maintainers of this file can make decisions to
# remove the workarounds in the future.
importlib-resources<2.0.0  # virtualenv 20.0.21 requires importlib-resources<2.0.0 (RELENG-2993)
pyparsing<3.0.0 # httplib2 0.20.1 requires pyparsing<3,>=2.4.2
EOF

    #Python 3.5 in Ubuntu 16.04 workaround
    if [[ -f /etc/lsb-release ]]; then
        # shellcheck disable=SC1091
        source /etc/lsb-release
        if [[ $DISTRIB_RELEASE == "16.04" && $DISTRIB_ID == "Ubuntu" ]]; then
            echo "WARNING: Python projects should move to Ubuntu 18.04 to continue receiving support"
            echo "zipp==1.1.0" >> "$requirements_file"
        fi
    fi

    python3 -m pip install --user --quiet --upgrade pip
    python3 -m pip install --user --quiet --no-warn-script-location --upgrade setuptools
    python3 -m pip install --user --quiet --no-warn-script-location --upgrade lftools[openstack]
    python3 -m pip install --user --quiet --no-warn-script-location --upgrade \
        --upgrade-strategy eager -r "$requirements_file"
    # installs are silent, show version details in log
    python3 --version
    python3 -m pip --version
    python3 -m pip freeze

    rm -rf "$requirements_file"
    touch /tmp/pre-build-complete
fi
