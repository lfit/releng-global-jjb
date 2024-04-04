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
echo "---> jjb-merge-job.sh"

workers="${JJB_WORKERS:-0}"

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

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

lf-activate-venv jenkins-job-builder setuptools==65.7.0

jenkins-jobs update --recursive --delete-old --workers "$workers" jjb/
