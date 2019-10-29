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

# A library of functions for LF/Jenkins bash scripts. In the general case, these
# functions should only use 'local' variables, and should NOT set
# shell/environment variables. If you want to make a
# variable available, provide a function that sets the variable: 'function
# lf_set_foo() {foo=asdf;}'. Any scripts that need access to the variable can
# call the 'set' function. This keeps the name-space pollution to a minimum.

# Shell variables that are shared between functions

_lf_done_file=".lf-done"

################################################################################
#
# Name:    lf-echo-stderr
#
# SYNOPSIS
#       source ~/lf-env.sh
#
#       lf-echo-stderr "this entire" "string will be sent to stderr"
#
# DESCRIPTION
#       This function will echo all command line aruments to 'stderr'
#
# RETURN VALUE
#       None
#
################################################################################

function lf-echo-stderr() { echo "$@" 1>&2; }

################################################################################
#
# NAME
#       lf-boolean()
#
# SYNOPSIS
#       # shellcheck disable=SC1090
#       source ~/lf-env.sh
#
#       if lf-boolean $VAR; then
#           echo "VAR is true"
#       fi
#
# DESCRIPTION
#       This function will return a BOOLEAN (true or false) based upon the value
#       of VAR. The value of VAR will be mapped to lower case. If VAR maps to
#       "true", return true(0). If VAR maps to "false", return false(1).  Any
#       other values will return false(2) and an error message.
#
# RETURN VALUES
#       true(0), false(1) or false(2)
#
################################################################################

function lf-boolean()
{
    if (( $# != 1 )); then
        echo "ERROR: ${FUNCNAME[0]}() line: ${BASH_LINENO[0]} : Missing required argument"
        return 1
    fi
    local bool
    bool=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    case $bool in
        true)  return 0 ;;
        false) return 1 ;;
        '')
           lf-echo-stderr "ERROR: ${FUNCNAME[0]}() line:{BASH_LINENO[0]} : A boolean cannot be a empty string" >&2
           return 2
           ;;
        *)
            lf-echo-stderr "ERROR: ${FUNCNAME[0]}() line: ${BASH_LINENO[0]} : Invalid value for a boolean: '$bool'"
            return 2
            ;;
    esac
}

################################################################################
#
# NAME
#       lf-venv-activate()
#
# SYNOPSIS
#       # shellcheck disable=SC1090
#       source ~/lf-env.sh
#
#       lf-venv-activate python3
#
# DESCRIPTION
#       This function will validate existance of 'python' venv. If it exists
#       'path-to-venv/bin' will be prepended to the PATH.
#
# RETURN VALUES
#       None
#
################################################################################

function lf-venv-activate()
{
    if (( $# != 1 )); then
        echo "${FUNCNAME[0]}(): Missing path operand"
        return 1
    fi
    local arg=$1
    local venv
    if [[ $arg =~ ^python ]] && type $arg > /dev/null ; then
        venv=~/.venv${arg#python}
    else
        venv=$arg
    fi
    # Validate the path to a VENV
    if [[ ! -f $venv/$_lf_done_file ]]; then
        lf-echo-stderr "ERROR: Is '$venv' a Python Environment ?"
        return 1
    fi
    echo "${FUNCNAME[0]}(): Adding $venv/bin to PATH"
    PATH=$venv/bin:$PATH

}  # ENd lf-venv-activate()

################################################################################
#
# NAME
#   lf-venv-create python [package]...
#
# SYNOPSIS
#   # shellcheck disable=SC1090
#   source ~/lf-env.sh
#
#   lf-venv-create python3 tox tox-pyenv virtualenv
#   lf-venv-create python3.6
#
# DESCRIPTION
#   This function will create/update a Python Virtual Environment (venv) based
#   on the python specified. The 'python' argument must be in the PATH. The venv
#   will be located in ~/.venv## where ## comes from the 'python' argument.
#   I.E. python3 -> ~/.venv3. The resulting venv will be left 'read-only' to
#   discourage the installation of any other packages (except by
#   lf-venv-create()). By default, only versioned packages will be installed, so
#   any required packages need to be specified.  By default the 'pip install
#   --upgrade' will be run multiple times. Sometimes pip needs that to get the
#   versioning correct.
#
# RETURN VALUES
#       None
#
################################################################################

function lf-venv-create()
{
    if (( $# < 1 )); then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Missing Python argument"
        return 1
    fi
    python=$1
    shift
    if ! type $python > /dev/null; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknown Python: $python"
        return 1
    fi
    local pkg_list="$@ "
    local venv=~/.venv${python#python}
    local suffix=$python-$$
    local pip_log=/tmp/pip_log.$suffix
    if [[ -f $venv/$_lf_done_file ]]; then
        echo "Venv Already Exists: '$venv'"
        return
    fi
    # Make sure noting is left over
    if [[ -d $venv ]]; then
        chmod -R +w $venv
        rm -rf $venv
    fi

    echo "Creating '$python' venv ($venv)"

    case $python in
    python2*|python)
        # For Python2, just create venv and install pip
        virtualenv -p $python $venv > $pip_log || return 1
        $venv/bin/pip install --upgrade pip > $pip_log || return 1
        $venv/bin/pip install --upgrade $pkg_list > $pip_log || return 1
        ;;
    python3*)
        # Include any packages that are tied to a specific version
        pkg_list+="jenkins-job-builder==2.8.0 "
        $python -m venv $venv > $pip_log
        $venv/bin/pip install --upgrade pip > $pip_log || return 1
        # Redirect errors for now
        $venv/bin/pip install --upgrade $pkg_list >> $pip_log 2> /dev/null || return 1
        # Generate list of packages
        pkg_list=$($venv/bin/pip freeze | awk -F '=' '{print $1}') || return 1
        # Update all packages, may need to run twice to get all versions
        # synced up. Ignore exit status on first try
        $venv/bin/pip install --upgrade $pkg_list >> $pip_log || true
        echo "Running 'pip --upgrade' to validate..."
        $venv/bin/pip install --upgrade $pkg_list >> $pip_log || return 1
        ;;
    *)
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: No support for: $python"
        return 1
        ;;
    esac

    touch $venv/$_lf_done_file
    # Once this venv is created, make it read-only
    chmod -R -w $venv
    # Archive output of 'pip freeze'
    mkdir -p $WORKSPACE/archives
    $venv/bin/pip freeze > $WORKSPACE/archives/freeze-log-$python || return 1
    rm -rf $pip_log

}   # End lf-venv-create()

################################################################################
#
# NAME
#       lf-venv-add()
#
# SYNOPSIS
#       # shellcheck disable=SC1090
#       source ~/lf-env.sh
#
#       lf-venv-add python3 pkg
#       or
#       lf-venv-add python2 pkg1 pkg2 pkg3
#
# DESCRIPTION
#       This function will add one or more python packages to an existing venv.
#       Attempts to add packages directly (pip) will result in errors because
#       the venv does not have 'write' permission.
#
# RETURN VALUES
#       None
#
################################################################################

function lf-venv-add()
{
    if (( $# < 2 )); then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Missing Package argument"
        return 1
    fi
    python=$1
    if ! type $python > /dev/null ; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknown Python: $python"
        return 1
    fi
    shift
    local venv=~/.venv${python#python}
    if [[ ! -f $venv/$_lf_done_file ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: '$venv' is not a valid venv"
        return 1
    fi
    local pkg_list=$*
    local pip_log=/tmp/pip_log-$$

    echo "Installing '$pkg_list' into $venv"
    chmod -R +w $venv
    rm $venv/$_lf_done_file
    $venv/bin/pip install --upgrade $pkg_list > $pip_log || return 1
    pkg_list=$($venv/bin/pip freeze | awk -F '=' '{print $1}') || return 1
    $venv/bin/pip install --upgrade $pkg_list > $pip_log || return 1
    touch $venv/$_lf_done_file
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
    # Disable 'unused-variable' check
    # shellcheck disable=SC2034
    maven_options="--show-version --batch-mode -Djenkins \
        -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
        -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r"
}
