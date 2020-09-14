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
echo "---> cmake-sonarqube.sh"

# Runs cmake then make using a wrapper for the SonarQube Jenkins plug-in
# https://docs.sonarqube.org/latest/analysis/languages/cfamily/

set -eux -o pipefail

build_dir="${BUILD_DIR:-$WORKSPACE/build}"
build_wrap_dir="${BUILD_WRAP_DIR:-$WORKSPACE/bw-output}"
cmake_opts="${CMAKE_OPTS:-}"
make_opts="${MAKE_OPTS:-}"

cd /tmp || exit 1
wget -q -O bw.zip https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
unzip -q bw.zip
sudo mv build-wrapper-* /opt/build-wrapper


SET_JDK_VERSION="${SET_JDK_VERSION:-openjdk11}"
echo "$SET_JDK_VERSION"
bash <(curl -s https://raw.githubusercontent.com/lfit/releng-global-jjb/master/shell/update-java-alternatives.sh)
# shellcheck disable=SC1091
source /tmp/java.env

mkdir -p "$build_dir"
cd "$build_dir" || exit 1


# $cmake_opts needs to wordsplit to pass options.
# shellcheck disable=SC2086
eval cmake -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" $cmake_opts ..

# $make_opts may be empty.
# shellcheck disable=SC2086
/opt/build-wrapper/build-wrapper-linux-x86-64 --out-dir "$build_wrap_dir" make $make_opts


echo "---> cmake-sonarqube.sh ends"
