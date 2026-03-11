#!/bin/sh
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2026 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> uv-install.sh"
# This shell script installs uv/uvx using the official shell install process

# Ensure we fail the job if any steps fail.
set -e

# $UV_VERSION : uv version to install (optional, defaults to latest)
UV_VERSION="${UV_VERSION:-}"

# Check if uv is already available (it may be in a non-standard location)
if ! command -v uv > /dev/null 2>&1; then
    if [ -x "$HOME/.local/bin/uv" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Determine if installation is needed
if command -v uv > /dev/null 2>&1; then
    current_version="$(uv --version | awk '{print $2}')"
    if [ -n "$UV_VERSION" ]; then
        if [ "$current_version" = "$UV_VERSION" ]; then
            echo "uv ${UV_VERSION} is already installed"
            uvx --version
            exit 0
        else
            echo "uv ${current_version} installed; replacing with ${UV_VERSION}"
        fi
    else
        echo "uv ${current_version} is already installed"
        uvx --version
        exit 0
    fi
fi

# Build the installer URL (versioned or latest)
if [ -n "$UV_VERSION" ]; then
    uv_install_url="https://astral.sh/uv/${UV_VERSION}/install.sh"
    echo "Installing uv/uvx version ${UV_VERSION} using shell installer"
else
    uv_install_url="https://astral.sh/uv/install.sh"
    echo "Installing uv/uvx (latest) using shell installer"
fi

uv_installer=$(mktemp /tmp/uv-install-XXXXXX.sh)
wget -nv -O "$uv_installer" "$uv_install_url"
sh "$uv_installer"
rm -f "$uv_installer"

# Ensure the installed binary is on the PATH
if ! command -v uvx > /dev/null 2>&1; then
    echo "Adding install location to PATH"
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "---> Validating uv/uvx install"

if ! uvx --version; then
    echo "ERROR: uv/uvx installation failed!"
    exit 1
fi