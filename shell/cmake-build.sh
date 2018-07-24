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
echo "---> cmake-build.sh"

build_dir="${BUILD_DIR:-$WORKSPACE/target}"
cmake_opts="${CMAKE_OPTS:-}"
make_opts="${MAKE_OPTS:-}"
# Not a misspelling as shellcheck reports.
# shellcheck disable=SC2153
project="${PROJECT//\//\-}"

################
# Script start #
################

set -eux -o pipefail

mkdir -p "$build_dir"
cd "$build_dir" || exit
# $cmake_opts needs to wordsplit to pass options.
# shellcheck disable=SC2086
cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" $cmake_opts ..
# $make_opts needs to wordsplit to pass options.
# shellcheck disable=SC2086
make $make_opts
make install

mkdir -p "$WORKSPACE/dist"
tar -cJvf "$WORKSPACE/dist/$project.tar.xz" -C "$INSTALL_PREFIX" .

sudo tar -xvf "$WORKSPACE/dist/$project.tar.xz" -C "/usr/local"
sudo ldconfig
