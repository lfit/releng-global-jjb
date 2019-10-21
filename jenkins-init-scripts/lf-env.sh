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

# Function to activate a Python Virtual Environment. The argument is either a
# path or a python executable. If the argument is a python executable check if
# it is in the PATH. The python exeuctable name will be converted to a path
# (~/.venv$version/bin) and then validated. If the argument is a path, the the
# path ($path/bin) is validatedIf no path is specified, return 1.

function lf-activate()
{
    if [[ $# != 1 ]]; then
        echo "lf-activate(): Missing path operand"
        return 1
    fi
    local arg=$1
    local venv_bin
    if [[ $arg =~ ^python && $(type $arg) ]]; then
        venv_bin=~/.venv${arg#python}/bin
    else
        venv_bin=$arg/bin
    fi
    # Validate the path to a VENV
    if [[ ! -d $venv_bin ]]; then
        lf-echoerr "ERROR: Is '$venv_bin' a Python Environment ?"
        return 1
    fi
    echo "lf-activate: Adding $venv_bin to PATH"
    PATH=$venv_bin:$PATH
}

# Create Python Virtual Environment for the specified version of python. This
# function may be called multiple times so if the venv has already been created
# just return. This function assumes that 'bash -e' is set.

function lf-create-venv()
{
    if [[ $# != 1 ]]; then
        lf-error "lf-create-user-venv(): ERROR: Missing Python argument"
        return 1
    fi
    python=$1
    if ! type $python ; then
        lf-error "lf-create-user-venv(): ERROR: Unknow Python: $python"
        return 1
    fi
    local venv=~/.venv${python#python}
    local done_file=$venv/.lf-done
    local suffix=$python-$$
    local pip_log=/tmp/pip_log.$suffix
    local req_list=/tmp/req_list.$suffix
    local pkg_list=/tmp/pkg_list.$suffix
    if [[ -f $done_file ]]; then
        echo "Venv Already Exits: '$venv'"
        return
    fi
    # Even if the 'done' files does not exist, make sure to clean up
    if [[ -d $venv ]]; then
        chmod -R +w $venv
        rm -rf $venv
    fi

    echo "Installing Required Packages in the $venv"
    cat << 'EOF' > $req_list
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

    case $python in
    python2*)
        lf-error "lf-create-user-venv(): ERROR: No support for: $python"
        return 1
        ;;
    python3*)
        $python -m venv $venv > $pip_log
        $venv/bin/pip install --upgrade pip > $pip_log
        $venv/bin/pip --version >> $pip_log
        # Redirect errors for now
        $venv/bin/pip install --upgrade -r $req_list >> $pip_log 2> /dev/null
        $venv/bin/pip freeze | awk -F '=' '{print $1}' > $pkg_list
        # Sometimes need to run twice to get all versions correct.
        if $venv/bin/pip install --upgrade -r $pkg_list >> $pip_log 2>&1 > /dev/null ; then
            echo "Run 'pip upgrade' to validate"
            $venv/bin/pip install --upgrade -r $pkg_list >> $pip_log
        fi
        ;;
    *)
        lf-error "lf-create-user-venv(): ERROR: No support for: $python"
        return 1
        ;;
    esac

    touch $done_file
    # Once this venv is created, make it read-only
    chmod -R -w $venv
    # Archive output of 'pip freeze'
    mkdir -p $WORKSPACE/archives
    $venv/bin/pip freeze > $WORKSPACE/archives/freeze-log-$python
    rm -rf $pip_log $pkg_list $req_list

}   # End lf-create-venv()

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
