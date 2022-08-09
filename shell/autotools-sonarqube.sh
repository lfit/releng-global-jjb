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

# Invokes configure and make with the specified options,
# using a wrapper for the SonarQube Jenkins plug-in
# https://docs.sonarqube.org/latest/analysis/languages/cfamily/
# Prereqs:
# The build minion has make, gcc etc.
# The project repo has an executable shell script "configure"
# Environment variables:
# WORKSPACE is a non-empty path (required)
# INSTALL_PREFIX is a non-empty path (required)
# CONFIGURE_OPTS has options for configure (optional, empty default)
# MAKE_OPTS has options for make (optional, empty default)
# BUILD_WRAP_DIR is a path (optional, this provides a usable default)

echo "---> autotools-sonarqube.sh"

# be careful and verbose
set -eux -o pipefail

c="$WORKSPACE/configure"
if [[ ! -f $c || ! -x $c ]]; then
    echo "ERROR: failed to find executable file $c"
    exit 1
fi

configure_opts="${CONFIGURE_OPTS:-}"
make_opts="${MAKE_OPTS:-}"
build_wrap_dir="${BUILD_WRAP_DIR:-$WORKSPACE/bw-output}"

# download and install the Sonar build wrapper
bw=bw.zip
wget -q -O "$bw" https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
unzip -q "$bw"
sudo mv build-wrapper-* /opt/build-wrapper
rm -f "$bw"

# use eval to disable bash quoting behavior;
# e.g., if configure-opts=CXXFLAGS="-O0 --coverage"
# configure needs to wordsplit to pass options
# shellcheck disable=SC2086
eval $c --prefix="$INSTALL_PREFIX" $configure_opts

# to analyze coverage, make must run tests and run gcov
# to process .gcno/.gcda files into .gcov files.
# use eval to disable bash quoting behavior
# $make_opts may be empty
# make needs to wordsplit to pass options
# shellcheck disable=SC2086
eval /opt/build-wrapper/build-wrapper-linux-x86-64 --out-dir \
    "$build_wrap_dir" make $make_opts

echo "---> autotools-sonarqube.sh ends"
