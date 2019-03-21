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

# This script takes the java-version variable to set the proper alternative
# for java, javac and java_sdk_openjdk for ubuntu or centos/fedora/redhat distros

JAVA_ENV_FILE="/tmp/java.env"

update-java-redhat() {
    if [[ "${SET_JDK_VERSION//[a-zA-Z]/}" = "11" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    else
        export JAVA_HOME="/usr/lib/jvm/java-1.${SET_JDK_VERSION//[a-zA-Z:-]/}.0-openjdk"
    fi
    sudo /usr/sbin/alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 1
    sudo /usr/sbin/alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 1
    sudo /usr/sbin/alternatives --install /usr/lib/jvm/java-openjdk java_sdk_openjdk "${JAVA_HOME}" 1
    sudo /usr/sbin/alternatives --set java "${JAVA_HOME}/bin/java"
    sudo /usr/sbin/alternatives --set javac "${JAVA_HOME}/bin/javac"
    sudo /usr/sbin/alternatives --set java_sdk_openjdk "${JAVA_HOME}"
    echo JAVA_HOME="$JAVA_HOME" > "$JAVA_ENV_FILE"
}

update-java-ubuntu() {
    export JAVA_HOME="/usr/lib/jvm/java-${SET_JDK_VERSION//[a-zA-Z:-]/}-openjdk-amd64"
    sudo /usr/bin/update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 1
    sudo /usr/bin/update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 1
    sudo /usr/bin/update-alternatives --install /usr/lib/jvm/java-openjdk java_sdk_openjdk "${JAVA_HOME}" 1
    sudo /usr/bin/update-alternatives --set java "${JAVA_HOME}/bin/java"
    sudo /usr/bin/update-alternatives --set javac "${JAVA_HOME}/bin/javac"
    sudo /usr/bin/update-alternatives --set java_sdk_openjdk "${JAVA_HOME}"
    echo JAVA_HOME="$JAVA_HOME" > "$JAVA_ENV_FILE"
}

echo "---> Updating Java version"
OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${OS}" in
    fedora|centos|redhat)
        echo "---> RedHat type system detected"
        update-java-redhat
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        update-java-ubuntu
    ;;
esac
java -version
echo JAVA_HOME="${JAVA_HOME}"
