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

def templateName = "steve"
def label = "a-label"

template = new JCloudsSlaveTemplate(
    templateName,
    label,
    slaveOptions
)

def cloudName = "cloud"
def endPointUrl = "https://endpoint.com"
def ignoreSsl = false
def zone = "zone"
templates = Collections.singletonList(template)
def credId = "cred"



defaultOptions = new SlaveOptions(
    DEFAULT_OPTIONS
)
cloud = new JCloudsCloud("a", "b", false, "d", defaultOptions, [template], credId)

def clouds = Jenkins.instance.clouds
clouds.replace(cloud)
