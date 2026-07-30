#!/bin/sh
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> update-java-alternatives.sh"
# This script takes the java-version variable to set the proper alternative
# for java, javac and java_sdk_openjdk for ubuntu or centos/fedora/redhat distros

JAVA_ENV_FILE="/tmp/java.env"

JAVA_RELEASE=$(echo "$SET_JDK_VERSION" | sed 's/[a-zA-Z]//g')
JAVA_RELEASE_NBR=$(echo "$SET_JDK_VERSION" | sed 's/[a-zA-Z:-]//g')
#TODO check whether is it worth keeping there 2 distinct variables
update_java_redhat() {
    if [ "${JAVA_RELEASE}" -ge 9 ]; then
        # Java 9 or newer: new version format
        export JAVA_HOME="/usr/lib/jvm/java-${JAVA_RELEASE}-openjdk"
    else
        # Java 8 or older: old version format
        export JAVA_HOME="/usr/lib/jvm/java-1.${JAVA_RELEASE_NBR}.0-openjdk"
    fi
}

update_java_ubuntu() {
    HOST_ARCH=$(dpkg --print-architecture)
    export JAVA_HOME="/usr/lib/jvm/java-${JAVA_RELEASE_NBR}-openjdk-${HOST_ARCH}"
}

echo "---> Updating Java version"
OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${OS}" in
    fedora|centos|redhat)
        echo "---> RedHat type system detected"
        update_java_redhat
	alternatives="/usr/sbin/alternatives"
    ;;
    ubuntu|debian)
        echo "---> Ubuntu/Debian system detected"
        update_java_ubuntu
	alternatives=$(which update-alternatives)
    ;;
esac

# Optional SDKMAN!-managed JDKs, opt-in only. Jobs keep using the distribution
# JDK resolved above unless they explicitly set JDK_PROVIDER=sdkman, which
# downstream repositories pass in as a job parameter or injected env var. This
# decouples the usable Java versions from what the distro packages, so a node
# can offer newer LTS/GA/EA releases without an OS upgrade, while leaving every
# existing job on the distribution JDK.
if [ "${JDK_PROVIDER:-distro}" = "sdkman" ]; then
    SDKMAN_JAVA="${SDKMAN_DIR:-/opt/sdkman}/candidates/java"
    SDKMAN_CANDIDATE=$(
        for candidate_dir in "$SDKMAN_JAVA/${JAVA_RELEASE_NBR}".* \
            "$SDKMAN_JAVA/${JAVA_RELEASE_NBR}"-*; do
            [ -d "$candidate_dir" ] && basename "$candidate_dir"
        done | sort -V | tail -1
    )
    if [ -n "$SDKMAN_CANDIDATE" ]; then
        echo "---> Using SDKMAN! JDK: $SDKMAN_CANDIDATE"
        JAVA_HOME="$SDKMAN_JAVA/$SDKMAN_CANDIDATE"
        export JAVA_HOME
    else
        echo "JDK_PROVIDER=sdkman requested but no SDKMAN! JDK matching" \
            "${JAVA_RELEASE_NBR} found under $SDKMAN_JAVA" >&2
        echo "---> Falling back to the distribution JDK"
    fi
fi

if ! [ -d "$JAVA_HOME" ]; then
    echo "$JAVA_HOME directory not found - trying to find an approaching one"
    if ls -d "$JAVA_HOME"*; then
    # shellcheck disable=SC2012
	JAVA_HOME=$(ls -d "$JAVA_HOME"* | head -1)
        export JAVA_HOME
    else
        echo "no $JAVA_HOME directory nor candidate found -exiting " >&2
        exit 17
    fi
fi

# If sudo is not found, the commands below will run anyway
SUDO_CMD=$(which sudo)

$SUDO_CMD "$alternatives" --install /usr/bin/java java "${JAVA_HOME}/bin/java" 1
$SUDO_CMD "$alternatives" --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 1
$SUDO_CMD "$alternatives" --install /usr/lib/jvm/java-openjdk java_sdk_openjdk "${JAVA_HOME}" 1
$SUDO_CMD "$alternatives" --set java "${JAVA_HOME}/bin/java"
$SUDO_CMD "$alternatives" --set javac "${JAVA_HOME}/bin/javac"
$SUDO_CMD "$alternatives" --set java_sdk_openjdk "${JAVA_HOME}"
echo JAVA_HOME="$JAVA_HOME" > "$JAVA_ENV_FILE"

java -version
echo JAVA_HOME="${JAVA_HOME}"
