#!/usr/bin/no-execute
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

import argparse
from datetime import datetime
import sys
import urllib.request
import json

import openstack

stack_name = sys.argv[1]

parser = argparse.ArgumentParser()
cloud = openstack.connect(options=parser)


def get_server_cost(server_id):
    flavor, seconds = get_server_info(server_id)

    url = "https://pricing.vexxhost.net/v1/pricing/%s/cost?seconds=%d"
    with urllib.request.urlopen(url % (flavor, seconds)) as response:
        data = json.loads(response.read())
    return data['cost']


def parse_iso8601_time(time):
    return datetime.strptime(time, "%Y-%m-%dT%H:%M:%S.%f")


def get_server_info(server_id):
    server = cloud.compute.find_server(server_id)
    diff = (datetime.utcnow() - parse_iso8601_time(server.launched_at))

    return server.flavor['original_name'], diff.total_seconds()


def get_server_ids(stack_name):
    servers = get_resources_by_type(stack_name, 'OS::Nova::Server')
    return [s['physical_resource_id'] for s in servers]


def get_resources_by_type(stack_name, resource_type):
    resources = get_stack_resources(stack_name)
    return [r for r in resources if r.resource_type == resource_type]


def get_stack_resources(stack_name):
    resources = []

    def _is_nested(resource):
        link_types = [l['rel'] for l in resource.links]
        if 'nested' in link_types:
            return True
        return False

    for r in cloud.orchestration.resources(stack_name):
        if _is_nested(r):
            resources += get_stack_resources(r.physical_resource_id)
            continue

        resources.append(r)

    return resources


if __name__ == "__main__":
    total_cost = 0.0
    for server in get_server_ids(stack_name):
        total_cost += get_server_cost(server)
    print("total:", total_cost)
