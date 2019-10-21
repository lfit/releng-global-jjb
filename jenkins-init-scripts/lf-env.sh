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
# function. This keeps the name-space pollution to a minimum.

################################################################################
# Functions
################################################################################

# Echo all arguments to stderr
function lf-echo-stderr() { echo "$@" 1>&2; }

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
        lf-echo-stderr "ERROR: $(basename $0) line: ${BASH_LINENO[0]} : A boolean cannot be a empty string" >&2
        return 1
    fi
    $bool || return 1
}

# Function to activate a Python Virtual Environment. The argument is either a
# path or a python executable. If the argument is a python executable check if
# it is in the PATH. The python executable name will be converted to a path
# (~/.venv$version/bin) and then validated. If the argument is a path, then the
# path ($path/bin) is validated. If no argument is specified, return 1.
#
# usage: lf-venv-activate path
#        lf-venv-activate python-executable

function lf-venv-activate()
{
    if [[ $# != 1 ]]; then
        echo "${FUNCNAME[0]}(): Missing path operand"
        return 1
    fi
    local arg=$1
    local venv_bin
    if [[ $arg =~ ^python ]] && type $arg > /dev/null ; then
        venv_bin=~/.venv${arg#python}/bin
    else
        venv_bin=$arg/bin
    fi
    # Validate the path to a VENV
    if [[ ! -d $venv_bin ]]; then
        lf-echo-stderr "ERROR: Is '$venv_bin' a Python Environment ?"
        return 1
    fi
    echo "${FUNCNAME[0]}(): Adding $venv_bin to PATH"
    PATH=$venv_bin:$PATH
}

# Create Python Virtual Environment for the specified version of python. This
# function may be called multiple times so if the venv has already been created
# just return.
#
# usage: lf-venv-create 'python-executable'

function lf-venv-create()
{
    if (( $# != 1 )); then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Missing Python argument"
        return 1
    fi
    python=$1
    if ! type $python > /dev/null; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknow Python: $python"
        return 1
    fi
    local venv=~/.venv${python#python}
    local done_file=$venv/.lf-done
    local suffix=$python-$$
    local pip_log=/tmp/pip_log.$suffix
    if [[ -f $done_file ]]; then
        echo "Venv Already Exists: '$venv'"
        return
    fi
    # If the done file does not exist, make sure to clean up
    if [[ -d $venv ]]; then
        chmod -R +w $venv
        rm -rf $venv
    fi

    echo "Creating venv located: $venv based on: $python"

    case $python in
    python2*)
        # For Python2, just create venve and install pip
        virtualenv -p $python $venv > $pip_log || return 1
        $venv/bin/pip install --upgrade pip > $pip_log || return 1
        ;;
    python3*)
        local pkg_list="git-review jenkins-job-builder lftools[openstack] "
        pkg_list+="niet python-heatclient python-openstackclient "
        pkg_list+="setuptools testresources tox yq"
        $python -m venv $venv > $pip_log
        $venv/bin/pip install --upgrade pip > $pip_log || return 1
        # Redirect errors for now
        $venv/bin/pip install --upgrade $pkg_list >> $pip_log 2> /dev/null || return 1
        # Generate list of packages
        pkg_list=$($venv/bin/pip freeze | awk -F '=' '{print $1}') || return 1
        # Update all packages, usuaally need to run twice to get all versions
        # correct.
        local upgrade_cmd="$venv/bin/pip install --upgrade $pkg_list"
        if $upgrade_cmd >> $pip_log 2>&1 > /dev/null ; then
            echo "Running 'pip upgrade' to validate..."
            $upgrade_cmd >> $pip_log || return 1
        fi
        ;;
    *)
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: No support for: $python"
        return 1
        ;;
    esac

    touch $done_file
    # Once this venv is created, make it read-only
    chmod -R -w $venv
    # Archive output of 'pip freeze'
    mkdir -p $WORKSPACE/archives
    $venv/bin/pip freeze > $WORKSPACE/archives/freeze-log-$python || return 1
    rm -rf $pip_log

}   # End lf-venv-create()

# Install Python Packages in pre-existing venv The first argument is a python
# executable, which needs to be in the PATH. The version is used to find the
# correct venv. If the venv does not already exist, return 1. The rest of the
# arguments are packages you want to add to the venv.
#
# usage: lf-venv-add 'python-executable' pkg [pkg]...

lf-venv-add()
{
    if (( $# < 2 )); then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Missing Package argument"
        return 1
    fi
    python=$1
    if ! type $python > /dev/null ; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknow Python: $python"
        return 1
    fi
    shift
    local venv=~/.venv${python#python}
    if [[ ! -f $venv/.lf-done ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: '$venv' is not a valid venv"
        return 1
    fi
    local pkg_list=$*
    local pip_log=/tmp/pip_log-$$

    echo "Installing '$pkg_list' into $venv"
    chmod -R +w $venv
    $venv/bin/pip install --upgrade $pkg_list > $pip_log || return 1
    pkg_list=$($venv/bin/pip freeze | awk -F '=' '{print $1}') || return 1
    $venv/bin/pip install --upgrade $pkg_list > $pip_log || return 1
    chmod -R -w $venv
    # Archive output of 'pip freeze'
    $venv/bin/pip freeze > $WORKSPACE/archives/freeze-log-$python || return 1

} # End lf-venv-add()

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
