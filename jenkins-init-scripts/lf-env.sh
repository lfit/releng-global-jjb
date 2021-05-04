#!/usr/bin/no-execute
# shellcheck shell=bash

# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
#
# A library of functions for LF/Jenkins bash scripts. In the general case, these
# functions should only use 'local' variables, and should NOT set
# shell/environment variables. If you want to make a variable available, provide
# a function that sets the variable: 'function lf_set_foo() {foo=asdf;}'. Any
# scripts that need access to the variable can call the 'set' function. This
# keeps the name-space pollution to a minimum.
#
# This script will be installed in ~jenkins by the Jenkins Init Script when the
# build agent boots. When the build starts it should already be installed.
#
################################################################################
#
# NAME
#       lf-echo-stderr
#
# SYNOPSIS
#   source ~/lf-env.sh
#
#   lf-echo-stderr "this entire" "string will be sent to stderr"
#
# DESCRIPTION
#   This function will echo all command line aruments to 'stderr'
#
# RETURN VALUE
#   None
#
################################################################################

function lf-echo-stderr {
    echo "$@" 1>&2
}

################################################################################
#
# NAME
#       lf-boolean
#
# SYNOPSIS
#   # shellcheck disable=SC1090
#   source ~/lf-env.sh
#
#   if lf-boolean $VAR; then
#       echo "VAR is true"
#   fi
#
# DESCRIPTION
#   This function will return a BOOLEAN (true or false) based upon the value
#   of VAR. The value of VAR will be mapped to lower case. If VAR maps to
#   "true", return true(0). If VAR maps to "false", return false(1).  Any
#   other values will return false(2) and an error message.
#
# RETURN VALUES
#   OK: 0
#   Fail: 1 or 2
#
################################################################################

function lf-boolean {
    if (( $# != 1 )); then
        echo "ERROR: ${FUNCNAME[0]}() line: ${BASH_LINENO[0]} : Missing Required Argument"
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
#   lf-activate-venv [-p|--python python] [--no-path]
#                    [--system-site-packages] [package]...
#
# SYNOPSIS
#   # shellcheck disable=SC1090
#   source ~/lf-env.sh
#
#   lf-activate-venv tox tox-pyenv
#   or
#   lf-activate-venv jenkins-job-builder
#   or
#   lf-activate-venv lftools
#   or
#   lf-activate-venv --python 3.6 git-review
#
# DESCRIPTION
#   This function will create a new Python Virtual Environment (venv) and
#   install the specified packages in the new venv.  The venv will be installed
#   in $lf_venv and by default, the $lf_venv/bin directory will be prepended
#   to the PATH.
#
#   The 'lf_venv' variable will be set so you can directly execute commands
#   in the venv with: $lf_venv/bin/command. Beware that subsequent calls to
#   lf-activate-venv() will overwrite 'lf_venv'.
#
#   By default all packages are installed with '--upgrade-strategy eager'.
#   The venv will always contain pip & virtualenv.
#
#   Some packages have a default version. If one of those packages is specified,
#   the 'version' specifier will be added for the install. If the version is
#   specified on the command line that version will be used.
#   The following packages have default versions:
#       Package                  Version
#       jenkins-job-builder      $JJB_VERSION
#
#   If the --python flag is specified, the specified python executable will be
#   used to create the venv. The --python option must be in the PATH. The venv
#   will be located in $lf_venv (/tmp/venv-####).
#
#   If the --no-path flag is specified, $lf_venv/bin will not be prepended to
#   the PATH.
#
#   If the --system-site-packages flag is specified, the --system-site-packages
#   flag will be passed to the inital 'pip install' (python3* only).
#
# RETURN VALUES
#   OK: 0
#   Fail: 1
#
################################################################################

function lf-activate-venv {
    lf_venv=$(mktemp -d /tmp/venv-XXXX)
    local python=python3
    local options
    local set_path=true
    local install_args=""
    options=$(getopt -o 'n:p:' -l 'no-path,python:,system-site-packages' -n "${FUNCNAME[0]}" -- "$@" )
    eval set -- "$options"
    while true; do
        case $1 in
            -n|--no-path) set_path=false ; shift   ;;
            -p|--python)  python=$2      ; shift 2 ;;
            --system-site-packages) install_args="--system-site-packages" ; shift ;;
            --) shift; break ;;
            *)  lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknown switch '$1'." ; return 1 ;;
        esac
    done
    if ! type "$python" > /dev/null; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknown Python: $python"
        return 1
    fi

    echo "${FUNCNAME[0]}(): INFO: Creating $python venv at $lf_venv"

    case $python in
    python2*)
        local pkg_list="$*"
        # For Python2, just create venv and install pip
        virtualenv -p "$python" "$lf_venv" || return 1
        "$lf_venv/bin/pip" install --upgrade --quiet pip || return 1
        if [[ -z $pkg_list ]]; then
            echo "${FUNCNAME[0]}(): WARNING: No packages to install"
            return 0
        fi
        echo "${FUNCNAME[0]}(): INFO: Installing: $pkg_list"
        # $pkg_list is expected to be unquoted
        # shellcheck disable=SC2086
        "$lf_venv/bin/pip" install --upgrade --quiet $pkg_list || return 1
        ;;
    python3*)
        local pkg_list=""
        # Add version specifier for some packages
        for arg in "$@"; do
            case $arg in
                jenkins-job-builder) pkg_list+="jenkins-job-builder==${JJB_VERSION:-2.8.0} " ;;
                *)                   pkg_list+="$arg " ;;
            esac
        done
        $python -m venv "$install_args" "$lf_venv" || return 1
        "$lf_venv/bin/pip" install --upgrade --quiet pip virtualenv || return 1
        if [[ -z $pkg_list ]]; then
            echo "${FUNCNAME[0]}(): WARNING: No packages to install"
            return 0
        fi
        echo "${FUNCNAME[0]}(): INFO: Installing: $pkg_list"
        # $pkg_list is expected to be unquoted
        # shellcheck disable=SC2086
        "$lf_venv/bin/pip" install --upgrade --quiet --upgrade-strategy eager \
                             $pkg_list || return 1
        ;;
    *)
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: No support for: $python"
        return 1
        ;;
    esac
    if $set_path; then
        echo "${FUNCNAME[0]}(): INFO: Adding $lf_venv/bin to PATH"
        PATH=$lf_venv/bin:$PATH
        return 0
    else
        echo "${FUNCNAME[0]}(): INFO: Path not set, lf_venv set to: $lf_venv"
    fi

}   # End lf-activate-venv

################################################################################
#
# NAME
#   lf-git-validate-jira-urls
#
# SYNOPSIS
#   # shellcheck disable=SC1090
#   source ~/lf-env.sh
#
#   lf-git-validate-jira-urls
#
# DESCRIPTION
#   Check for JIRA URLS in the commit message
#
# RETURN VALUES
#   OK: 0
#   Fail: 1
#
################################################################################

function lf-git-validate-jira-urls {
    echo "Checking for JIRA URLs in commit message..."
    # if JIRA_URL is not defined, nothing to do
    if [[ -v JIRA_URL ]]; then
        base_url=$(echo "$JIRA_URL" | awk -F'/' '{print $3}')
        jira_link=$(git rev-list --format=%B --max-count=1 HEAD | grep -io "http[s]*://$base_url/" || true)
        if [[ -n $jira_link ]]; then
            lf-echo-stderr "${FUNCNAME[0]}(): ERROR: JIRA URL found in commit message"
            lf-echo-stderr 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
            return 1
        fi
    else
        echo "${FUNCNAME[0]}(): WARNING: JIRA_URL not set, continuing anyway"
    fi
    return 0
}

################################################################################
#
# NAME
#   lf-jjb-check-ascii
#
# SYNOPSIS
#   # shellcheck disable=SC1090
#   source ~/lf-env.sh
#
#   lf-jjb-check-ascii
#
# DESCRIPTION
#   Check for JJB YAML files containing non-printable ascii characters. This
#   function must be run from the top of the global-jjb repo.
#
# RETURN VALUES
#   OK: 0
#   Fail: 1
#
################################################################################

function lf-jjb-check-ascii {
    if [[ ! -d "jjb" ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: missing jjb directory"
        lf-echo-stderr "This function can only be run from top of global-jjb directory"
        return 1
    fi
    if LC_ALL=C grep -I -r '[^[:print:][:space:]]' jjb/; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Found YAML files containing non-printable characters."
        return 1
    fi
    echo "${FUNCNAME[0]}(): INFO: All JJB YAML files contain only printable ASCII characters"
    return 0
}

################################################################################
# Functions that assign Variables
################################################################################

# These variables are shell (local) variables and need to be lower-case so
# Shellcheck knows they are shell variables and will check for
# 'used-before-set'.

function lf-set-maven-options {
    # Disable 'unused-variable' check
    # shellcheck disable=SC2034
    maven_options="--show-version --batch-mode -Djenkins \
        -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
        -Dmaven.repo.local=/tmp/r -Dorg.ops4j.pax.url.mvn.localRepository=/tmp/r"
}
