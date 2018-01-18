/*
 * SPDX-License-Identifier: EPL-1.0
 * Copyright (c) 2018 The Linux Foundation and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

 /**
  * Manage Jenkins OpenStack cloud configuration
  */

import jenkins.plugins.openstack.compute.JCloudsCloud
import jenkins.plugins.openstack.compute.JCloudsSlaveTemplate
import jenkins.plugins.openstack.compute.SlaveOptions
import jenkins.plugins.openstack.compute.slaveopts.BootSource
import jenkins.plugins.openstack.compute.slaveopts.LauncherFactory


def bs = new BootSource.Image("Image")
def hardwareId = "hardwareId"
def networkId = "networkId"
def userDataId = "userDataId"
def instanceCap = 500
def floatingIpPool = ""
def securityGroups = "Default"
def availabilityZone = "cmyk"
def startTimeout = 100000
def keyPairName = "jenkins"
def numExecutors = 1
def jvmOptions = ""
def fsRoot = "/w"
def launcherFactory = new LauncherFactory.SSH("id", "path")
def retentionTIme = 1

slaveOptions = new SlaveOptions(
    bs,
    hardwareId,
    networkId,
    userDataId,
    instanceCap,
    floatingIpPool,
    securityGroups,
    availabilityZone,
    startTimeout,
    keyPairName,
    numExecutors,
    jvmOptions,
    fsRoot,
    launcherFactory,
    retentionTIme
)

def clouds = Jenkins.instance.clouds
clouds.removeAll { it instanceof JCloudsCloud }
