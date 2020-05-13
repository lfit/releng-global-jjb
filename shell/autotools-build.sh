#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Invokes configure and make with the specified options.
# Optionally runs make install and tars up all files from the install prefix,
# then uses sudo to extract those files to /usr/local and runs ldconfig,
# leaving shared lib(s) ready for use.
# Prereqs:
# The build minion has make, gcc etc.
# The project repo has an executable shell script "configure"
# Environment variables:
# WORKSPACE is a non-empty path (required)
# INSTALL_PREFIX is a non-empty path (required)
# PROJECT is a non-empty name (required)
# CONFIGURE_OPTS has options for configure (optional, empty default)
# MAKE_OPTS has options for make (optional, empty default)
# INSTALL is "true" or "false" (optional, default false)

echo "---> autotools-build.sh"

# be careful and verbose
set -eux -o pipefail

c="$WORKSPACE/configure"
if [[ ! -f $c || ! -x $c ]]; then
    echo "ERROR: failed to find executable file $c"
    exit 1
fi

configure_opts="${CONFIGURE_OPTS:-}"
make_opts="${MAKE_OPTS:-}"
install="${INSTALL:-false}"
# Not a misspelling as shellcheck reports.
# shellcheck disable=SC2153
project="${PROJECT//\//\-}"

# use eval to disable bash quoting behavior;
# e.g., if configure-opts=CXXFLAGS="-O0 --coverage"
# configure needs to wordsplit to pass options
# shellcheck disable=SC2086
eval $c --prefix="$INSTALL_PREFIX" $configure_opts

# show make version to assist debugging
make -version
# use eval to disable bash quoting behavior
# $make_opts may be empty
# make needs to wordsplit to pass options
# shellcheck disable=SC2086
eval make $make_opts

if [[ $install == true ]]; then
    make install
    mkdir -p "$WORKSPACE/dist"
    tar -cJvf "$WORKSPACE/dist/$project.tar.xz" -C "$INSTALL_PREFIX" .
    sudo tar -xvf "$WORKSPACE/dist/$project.tar.xz" -C "/usr/local"
    sudo ldconfig
fi

echo "---> autotools-build.sh ends"
