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
 * Manage Jenkins Global Properties by injecting configuration defined here
 *
 * In LFCI a Jenkins job script will replace the JENKINS_URL line below and
 * inject the managed list of global variables.
 */

def global_vars = [
    'JENKINS_URL': 'https://localhost:8080',
]

def gnode_prop = Jenkins.getInstance().getGlobalNodeProperties()
def properties = new hudson.slaves.EnvironmentVariablesNodeProperty()
gnode_prop.replace(properties)
env_vars = properties.getEnvVars()

env_vars.clear()
global_vars.each{ k, v -> env_vars.put(k, v) }
instance.save()
