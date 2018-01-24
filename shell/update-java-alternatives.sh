#!/bin/bash

SET_JDK_VERSION=${java-version}

update-java-rh() {
    export JAVA_HOME="/usr/lib/jvm/java-1.${SET_JDK_VERSION: -1}.0-openjdk"
    sudo /usr/sbin/alternatives --set java ${JAVA_HOME}/bin/java
    sudo /usr/sbin/alternatives --set javac ${JAVA_HOME}/bin/javac
    sudo /usr/sbin/alternatives --set java_sdk_openjdk ${JAVA_HOME}
    mvn --version
    echo JAVA_HOME=$JAVA_HOME
}

update-java-ubuntu() {
    export JAVA_HOME="/usr/lib/jvm/java-${SET_JDK_VERSION: -1}-openjdk"
    sudo /usr/sbin/alternatives --set java ${JAVA_HOME}/bin/java
    sudo /usr/sbin/alternatives --set javac ${JAVA_HOME}/bin/javac
    sudo /usr/sbin/alternatives --set java_sdk_openjdk ${JAVA_HOME}
    mvn --version
    echo JAVA_HOME=$JAVA_HOME
}

echo "---> Updating JAVA version"
OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

case "${OS}" in
    fedora|centos|redhat)
        echo "---> RH type system detected"
        update-java-rh
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        update-java-ubuntu
    ;;
esac
