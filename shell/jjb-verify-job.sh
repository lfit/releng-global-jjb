#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> jjb-verify-job.sh"

set -eufo pipefail

# Functions copied from lf-env.sh to allow tweaking.
function lf-echo-stderr () {
    echo "$@" 1>&2
}

function lf-git-validate-jira-urls () {
    echo "Checking for JIRA URLs in commit message..."
    # if JIRA_URL is not defined, nothing to do
    if [[ -v JIRA_URL ]]; then
        base_url=$(echo "$JIRA_URL" | awk -F'/' '{print $3}')
        jira_link=$(git rev-list --format=%B --max-count=1 HEAD | \
                    grep -io "http[s]*://$base_url/" || true)
        if [[ -n $jira_link ]]; then
            lf-echo-stderr \
            "${FUNCNAME[0]}(): ERROR: JIRA URL found in commit message"
            lf-echo-stderr \
            'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>,'\
            ' instead of URLs'
            return 1
        fi
    else
        echo "${FUNCNAME[0]}(): WARNING: JIRA_URL not set, continuing anyway"
    fi
    return 0
}

function lf-jjb-check-ascii () {
    if [[ ! -d "jjb" ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: missing jjb directory"
        lf-echo-stderr \
        "This function can only be run from top of global-jjb directory"
        return 1
    fi
    if LC_ALL=C grep -I -r '[^[:print:][:space:]]' jjb/; then
        lf-echo-stderr \
        "${FUNCNAME[0]}(): ERROR: Found YAML files containing"\
        " non-printable characters."
        return 1
    fi
    echo "${FUNCNAME[0]}(): INFO: All JJB YAML files contain only printable"\
    " ASCII characters"
    return 0
}

function lf-pyver() {
    local py_version_xy="${1:-python3}"
    local py_version_xyz=""

    pyenv versions | sed 's/^[ *]* //' | awk '{ print $1 }' | grep -E '^[0-9.]*[0-9]$' \
        > "/tmp/.pyenv_versions"
    if [[ ! -s "/tmp/.pyenv_versions" ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: pyenv not available"
        return 1
    fi

    # strip out any prefix for (ex: 'python3.8' or 'v3.8') and match regex
    # to the output return by pyenv
    py_version_xyz=$(grep "^${py_version_xy//[a-zA-Z]/}" "/tmp/.pyenv_versions" |
        sort -V | tail -n 1;)
    if [[ -z ${py_version_xyz} ]]; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Not installed on host: ${py_version_xy}"
        return 1
    fi
    echo "${py_version_xyz}"
    return 0
}

# Compared to lf-env.sh, this looks at RESOLVED_JJB_VERSION.
lf-activate-venv () {
    lf_venv=$(mktemp -d /tmp/venv-XXXX)
    local venv_file="/tmp/.os_lf_venv"
    local python=python3
    local options
    local set_path=true
    local install_args=""
    # set -x
    options=$(getopt -o 'np:v:' -l 'no-path,system-site-packages,python:,venv-file:' \
                -n "${FUNCNAME[0]}" -- "$@" )
    eval set -- "$options"
    while true; do
        case $1 in
            -n|--no-path) set_path=false ; shift   ;;
            -p|--python)  python="$2"      ; shift 2 ;;
            -v|--venv-file) venv_file="$2" ; shift 2 ;;
            --system-site-packages) install_args="--system-site-packages" ;
                                    shift ;;
            --) shift; break ;;
            *)  lf-echo-stderr \
                "${FUNCNAME[0]}(): ERROR: Unknown switch '$1'." ;
                return 1 ;;
        esac
    done

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
        # Use pyenv for selecting the python version
        if [[ -d "/opt/pyenv" ]]; then
            echo "Setup pyenv:"
            export PYENV_ROOT="/opt/pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            pyenv versions
            if command -v pyenv 1>/dev/null 2>&1; then
                eval "$(pyenv init - --no-rehash)"
                # shellcheck disable=SC2046
                pyenv local $(lf-pyver "${python}")
            fi
        fi

        # Add version specifier for some packages
        for arg in "$@"; do
            case $arg in
                jenkins-job-builder)
                    pkg_list+="jenkins-job-builder==${RESOLVED_JJB_VERSION} " ;;
                *)                   pkg_list+="$arg " ;;
            esac
        done

        # Precedence:
        # - Re-use venv:
        #     1. --venv-file <path/to/file> as lf_venv
        #     2. default: "/tmp/.os_lf_venv"
        # - Create new venv when 1. and 2. is absent
        if [[ -f "$venv_file" ]]; then
            lf_venv=$(cat "$venv_file")
            echo "${FUNCNAME[0]}(): INFO: Reuse venv:$lf_venv from" \
                "file:$venv_file"
        elif [[ ! -f "$venv_file" ]]; then
            if [[ -n "$install_args" ]]; then
                $python -m venv "$install_args" "$lf_venv" || return 1
            else
                $python -m venv "$lf_venv" || return 1
            fi
            echo "${FUNCNAME[0]}(): INFO: Creating $python venv at $lf_venv"
            echo "$lf_venv" > "$venv_file"
            echo "${FUNCNAME[0]}(): INFO: Save venv in file: $venv_file"
        fi

        "$lf_venv/bin/python3" -m pip install --upgrade --quiet pip \
                        virtualenv || return 1
        if [[ -z $pkg_list ]]; then
            echo "${FUNCNAME[0]}(): WARNING: No packages to install"
        else
            echo "${FUNCNAME[0]}(): INFO: Installing: $pkg_list"
            # $pkg_list is expected to be unquoted
            # shellcheck disable=SC2086
            "$lf_venv/bin/python3" -m pip install --upgrade --quiet \
                        --upgrade-strategy eager $pkg_list || return 1
        fi
        ;;
    *)
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: No support for: $python"
        return 1
        ;;
    esac

    if ! type "$python" > /dev/null; then
        lf-echo-stderr "${FUNCNAME[0]}(): ERROR: Unknown Python: $python"
        return 1
    fi

    if $set_path; then
        echo "${FUNCNAME[0]}(): INFO: Adding $lf_venv/bin to PATH"
        PATH=$lf_venv/bin:$PATH
        return 0
    else
        echo "${FUNCNAME[0]}(): INFO: Path not set, lf_venv set to: $lf_venv"
    fi

}   # End lf-activate-venv

lf-git-validate-jira-urls
lf-jjb-check-ascii

lf-activate-venv --python python3 --venv-file /tmp/.jjb_venv \
    jenkins-job-builder setuptools==65.7.0

jenkins-jobs test --recursive -o archives/job-configs --config-xml jjb/

# Enable 'globbing'
set +f
# NGINX is very sluggish with directories containing large numbers of objects
# Add another directory level named {a..z} and move directories to them.
# Directories beginning with {0..9} or {A..Z} are left at the top level.
(   cd archives/job-configs
    for letter in {a..z}; do
        if ls -d "$letter"* > /dev/null 2>&1; then
            mkdir .tmp
            mv "$letter"* .tmp
            mv .tmp "$letter"
        fi
    done
)

(   cd archives
    echo "INFO: Archiving $(find job-configs -name \*.xml | wc -l) job configurations"
    tar -cJf job-configs.tar.xz job-configs
    rm -rf job-configs
)
