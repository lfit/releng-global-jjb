#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> openstack-stack-delete.sh"

set -euf -o pipefail

# shellcheck disable=SC1090
source ~/lf-env.sh

lf-activate-venv lftools[openstack] python-openstackclient

cat << 'EOF' > /tmp/patch
diff --git a/docs/commands/openstack.rst b/docs/commands/openstack.rst
index aeffa8f..2dacce9 100644
--- a/docs/commands/openstack.rst
+++ b/docs/commands/openstack.rst
@@ -81,3 +81,13 @@ delete
 Delete existing stack.
 
 .. program-output:: lftools openstack --os-cloud docs stack delete --help
+
+
+cost
+^^^^
+
+Get total cost of existing stack.
+
+.. program-output:: lftools openstack --os-cloud docs stack cost --help
+
+Return sum of costs for each member of the running stack.
diff --git a/lftools/openstack/cmd.py b/lftools/openstack/cmd.py
index cc3dde4..4018b92 100644
--- a/lftools/openstack/cmd.py
+++ b/lftools/openstack/cmd.py
@@ -224,6 +224,16 @@ def delete(ctx, name_or_id, force, timeout):
         timeout=timeout)
 
 
+@click.command()
+@click.argument('stack_name')
+@click.pass_context
+def cost(ctx, stack_name):
+    """Get Total Stack Cost."""
+    os_stack.cost(
+        ctx.obj['os_cloud'],
+        stack_name)
+
+
 @click.command(name='delete-stale')
 @click.argument('jenkins_urls', nargs=-1)
 @click.pass_context
@@ -242,6 +252,7 @@ def delete_stale(ctx, jenkins_urls):
 stack.add_command(create)
 stack.add_command(delete)
 stack.add_command(delete_stale)
+stack.add_command(cost)
 
 
 @openstack.group()
diff --git a/lftools/openstack/stack.py b/lftools/openstack/stack.py
index 42bf542..5245670 100644
--- a/lftools/openstack/stack.py
+++ b/lftools/openstack/stack.py
@@ -12,13 +12,17 @@
 
 __author__ = 'Thanh Ha'
 
+from datetime import datetime
+import json
 import logging
 import sys
 import time
+import urllib.request
 
 import shade
 
 from lftools.jenkins import Jenkins
+import openstack
 
 log = logging.getLogger(__name__)
 
@@ -74,6 +78,58 @@ def create(os_cloud, name, template_file, parameter_file, timeout=900, tries=2):
     print('------------------------------------')
 
 
+def cost(os_cloud, stack_name):
+    """Get current cost info for the stack.
+
+    Return the cost in dollars & cents (x.xx).
+    """
+    def get_server_cost(server_id):
+        flavor, seconds = get_server_info(server_id)
+        url = "https://pricing.vexxhost.net/v1/pricing/%s/cost?seconds=%d"
+        with urllib.request.urlopen(url % (flavor, seconds)) as response:  # nosec
+            data = json.loads(response.read())
+        return data['cost']
+
+    def parse_iso8601_time(time):
+        return datetime.strptime(time, "%Y-%m-%dT%H:%M:%S.%f")
+
+    def get_server_info(server_id):
+        server = cloud.compute.find_server(server_id)
+        diff = (datetime.utcnow() - parse_iso8601_time(server.launched_at))
+        return server.flavor['original_name'], diff.total_seconds()
+
+    def get_server_ids(stack_name):
+        servers = get_resources_by_type(stack_name, 'OS::Nova::Server')
+        return [s['physical_resource_id'] for s in servers]
+
+    def get_resources_by_type(stack_name, resource_type):
+        resources = get_stack_resources(stack_name)
+        return [r for r in resources if r.resource_type == resource_type]
+
+    def get_stack_resources(stack_name):
+        resources = []
+
+        def _is_nested(resource):
+            link_types = [l['rel'] for l in resource.links]
+            if 'nested' in link_types:
+                return True
+            return False
+
+        for r in cloud.orchestration.resources(stack_name):
+            if _is_nested(r):
+                resources += get_stack_resources(r.physical_resource_id)
+                continue
+            resources.append(r)
+        return resources
+
+    cloud = openstack.connect(os_cloud)
+
+    total_cost = 0.7
+    for server in get_server_ids(stack_name):
+        total_cost += get_server_cost(server)
+    print("total: " + str(total_cost))
+
+
 def delete(os_cloud, name_or_id, force, timeout=900):
     """Delete a stack.
 
diff --git a/releasenotes/notes/add-openstack-cost-464444d8cf0bdfa5.yaml b/releasenotes/notes/add-openstack-cost-464444d8cf0bdfa5.yaml
new file mode 100644
index 0000000..d82656d
--- /dev/null
+++ b/releasenotes/notes/add-openstack-cost-464444d8cf0bdfa5.yaml
@@ -0,0 +1,6 @@
+---
+features:
+  - |
+    Add openstack cost command. The cost is sum of the costs of each member of
+    the running stack.
+    https://jira.linuxfoundation.org/browse/RELENG-2550
EOF

set -x
git clone https://gerrit.linuxfoundation.org/infra/releng/lftools /tmp/lftools
cd /tmp/lftools
git apply /tmp/patch > /dev/null
pip install -e . > /dev/null
cd -
set +x

echo "INFO: Retrieving stack cost for: $OS_STACK_NAME"
if ! lftools openstack --os-cloud $OS_CLOUD stack cost $OS_STACK_NAME > stack-cost; then
    echo "WARNING: Unable to get stack costs, continuing anyway"
    echo "total: Unknown" > stack-cost
    exit_status=1
else
    echo "DEBUG: Successfully retrieved stack cost: $(cat stack-cost)"
    exit_status=0
fi

# Delete the stack even if the stack-cost script fails
lftools openstack --os-cloud "$OS_CLOUD" stack delete "$OS_STACK_NAME" \
    | echo "INFO: $(cat)"

exit $exit_status
