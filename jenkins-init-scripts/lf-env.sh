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

# Function to safely evaluate booleans
# If the boolean equal '' it is an Fatal Error
# Note the case of boolean will be ignored (always mapped to lower-case)
function lf-boolean()
{
    local bool
    bool=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ -z $bool ]] ; then
        # Output script name & line number of call to function
        lf-echoerr "ERROR: $(basename $0) line: ${BASH_LINENO[0]} : A boolean cannot be a empty string" >&2
        exit 1
    fi
    $bool
}

# Function to activate a Python Virtual Environment
# Just validate the path and add 'bin' to the path
function lf-activate()
{
    local venv_path=$1
    # Validate the path to a VENV
    if [[ ! -d $venv_path/bin ]]; then
        lf-echoerr "ERROR: Is '$venv_path' a Python Environment ?"
        return 1
    fi
    PATH=$venv_path/bin:$PATH
}

################################################################################
# Functions that assign Variables
################################################################################

# Although these variables are 'shell' variables, they need to be upper-case so
# 'shellcheck' does check for 'used-before-set' when they are referenced.

function lf_set_maven_options()
{
    # shellcheck disable=SC2034  # Disable 'unused-varible' check
    MAVEN_OPTIONS=$(echo --show-version --batch-mode -Djenkins \
        -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
        -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r)
}
