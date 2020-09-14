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

# Creates a build subdir then invokes cmake and make from that dir with the
# specified install prefix and options. Optionally runs make install and tars
# up all files from the install prefix, then uses sudo to extract those files
# to /usr/local and run ldconfig, leaving shared lib(s) ready for use.
# Prereqs:
# The build minion has cmake, make, gcc etc.
# Environment variables:
# WORKSPACE is a non-empty path (required)
# CMAKE_INSTALL_PREFIX is a non-empty path (required)
# PROJECT is a non-empty name (required)
# BUILD_DIR is a path (optional; has usable default)
# CMAKE_OPTS has options for cmake (optional, empty default)
# MAKE_OPTS has options for make (optional, empty default)
# INSTALL is "true" or "false" (optional, default true)

echo "---> cmake-build.sh"

# be careful and verbose
set -eux -o pipefail

build_dir="${BUILD_DIR:-$WORKSPACE/target}"
cmake_opts="${CMAKE_OPTS:-}"
make_opts="${MAKE_OPTS:-}"
install="${INSTALL:-true}"
# Not a misspelling as shellcheck reports.
# shellcheck disable=SC2153
project="${PROJECT//\//\-}"

SET_JDK_VERSION="${SET_JDK_VERSION:-openjdk11}"
echo "$SET_JDK_VERSION"
bash <(curl -s https://raw.githubusercontent.com/lfit/releng-global-jjb/master/shell/update-java-alternatives.sh)
# shellcheck disable=SC1091
source /tmp/java.env

mkdir -p "$build_dir"
cd "$build_dir" || exit
cmake -version
# $cmake_opts needs to wordsplit to pass options.
# shellcheck disable=SC2086
eval cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" $cmake_opts ..
make -version
# $make_opts needs to wordsplit to pass options.
# shellcheck disable=SC2086
make $make_opts

if [[ $install == true ]]; then
    make install
    mkdir -p "$WORKSPACE/dist"
    tar -cJvf "$WORKSPACE/dist/$project.tar.xz" -C "$INSTALL_PREFIX" .
    sudo tar -xvf "$WORKSPACE/dist/$project.tar.xz" -C "/usr/local"
    sudo ldconfig
fi

echo "---> cmake-build.sh ends"
