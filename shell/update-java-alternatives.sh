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

update-java-redhat() {
    export JAVA_HOME="/usr/lib/jvm/java-1.${SET_JDK_VERSION: -1}.0-openjdk"
    sudo /usr/sbin/alternatives --set java "${JAVA_HOME}/bin/java"
    sudo /usr/sbin/alternatives --set javac "${JAVA_HOME}/bin/javac"
    sudo /usr/sbin/alternatives --set java_sdk_openjdk "${JAVA_HOME}"
    java -version
    echo JAVA_HOME="${JAVA_HOME}"
}

update-java-ubuntu() {
    export JAVA_HOME="/usr/lib/jvm/java-${SET_JDK_VERSION: -1}-openjdk-amd64"
    sudo /usr/sbin/alternatives --set java "${JAVA_HOME}/bin/java"
    sudo /usr/sbin/alternatives --set javac "${JAVA_HOME}/bin/javac"
    sudo /usr/sbin/alternatives --set java_sdk_openjdk "${JAVA_HOME}"
    java -version
    echo JAVA_HOME="${JAVA_HOME}"
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
