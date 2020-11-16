#!/usr/bin/env python

import sys
import ruamel.yaml
yaml = ruamel.yaml.YAML()

kvlist = []
output = {}
envdict = {"env":kvlist}

with open("/tmp/oran/ci-management/jenkins-config/global-vars-sandbox.sh") as myfile:
    for line in myfile:
        name, var = line.partition("=")[::2]
        varstripped = var.strip()
        kvlist.append({"key": name, "value": varstripped})
output.update({'jenkins': {'globalNodeProperties': [{'envVars':envdict}]}})

yaml.dump(output, sys.stdout)
