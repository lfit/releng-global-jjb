#!/usr/bin/no-execute

# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# A library of functions for LF/Jenkins bash scripts. In the general case, do
# NOT set shell variables here. If you want to make a variable available,
# provide a function that sets the variable: 'function lf_set_foo()
# {foo=asdf;}'. Any scripts that need access to the variable can call the 'set'
# function. This keeps the name-space polution to a minimum.

################################################################################
# Functions
################################################################################

# Execute pip from 'user' venv
function lf-pip() { /home/jenkins/.local/bin/pip "$@" ; }

# Echo all arguments to stderr
function lf-echoerr() { echo "$@" 1>&2; }

# Function to safely evaluate booleans If the boolean equal '' it is a Fatal
# Error. Note the case of boolean will be ignored (always mapped to lower-case)

function lf-boolean()
{
    if [[ $# != 1 ]]; then
        echo "lf-boolean(): Missing boolean operand"
        return 1
    fi
    local bool
    bool=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ -z $bool ]] ; then
        # Output script name & line number of call to function
        lf-echoerr "ERROR: $(basename $0) line: ${BASH_LINENO[0]} : A boolean cannot be a empty string" >&2
        return 1
    fi
    $bool
}

# Function to activate a Python Virtual Environment. Validate the path and add
# 'bin' to the path. If no path is specified, default to '~/.local'

function lf-activate()
{
    local venv_path
    if [[ $# == 0 ]]; then
        venv_path=~/.local
    elif [[ $# == 1 ]]; then
        venv_path=$1
    else
        lf-echoerr "lf-activate(): ERROR: Only one dir expected"
        return 1
    fi
    # Validate the path to a VENV
    if [[ ! -d $venv_path/bin ]]; then
        lf-echoerr "ERROR: Is '$venv_path' a Python Environment ?"
        return 1
    fi
    echo "lf-activate(): Added $venv_path to PATH"
    PATH=$venv_path/bin:$PATH
}

# Create 'user' Python Virtual Environment (~/.local) This function may be
# called multiple times within a build so if the venv has already been created
# just quietly return. This function assumes that 'bash -e' is set.

function lf-create-user-venv()
{
    local venv=~/.local
    local requirements_file=/tmp/lf-requirements_file$$
    local done_file=$venv/.lf-done
    local pip_log=/tmp/pip.log$$

    if [[ -f $done_file ]]; then
        echo "User Venv Already Exists"
        return
    fi
    if [[ -d $venv ]]; then
        chmod -R +w $venv
        rm -rf $venv
    fi

    echo "Installing Required Packages in the 'user' VENV"
    cat << 'EOF' > $requirements_file
git-review
jenkins-job-builder
lftools[openstack]
niet
python-heatclient
python-openstackclient
setuptools
testresources
tox
yq
EOF

    python3 -m pip install --user -r "$requirements_file" pip > $pip_log
    touch $done_file
    #chmod -R -w $venv
    # Archive the pip log. The 'pip' command can have 'version conflict' errors
    # and it will still return '0' status, but the info will be in the log.
    mkdir -p $WORKSPACE/archives
    cp $pip_log $WORKSPACE/archives/pip-install.log
    rm -rf $requirements_file $pip_log

}   # End lf-create-user-venv()

################################################################################
# Functions that assign Variables
################################################################################

# These variables are shell (local) variables and need to be lower-case so
# Shellcheck knows they are shell variables and will check for
# 'used-before-set'.

function lf-set-maven-options()
{
    # shellcheck disable=SC2034  # Disable 'unused-variable' check
    maven_options="--show-version --batch-mode -Djenkins \
        -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
        -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r"
}
