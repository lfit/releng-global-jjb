#!/usr/bin/env python

import argparse
import configparser
import sys
import os
import ruamel.yaml
yaml = ruamel.yaml.YAML()

kvlist = []
output = {}
envdict = {"env":kvlist}

def dir_path(path):
    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f"readable_dir:{path} is not a valid path")

def parse_arguments():
    casc_d_dir = "/var/lib/jenkins/casc.d/community.d"
    parser = argparse.ArgumentParser(
        description='Create jcasc yaml from path to jenkins config dir.')
    parser.add_argument('--path', type=dir_path,
                        help="Path to jenkins-admin directory")
    parser.add_argument('--sandbox', type=bool, default=False,
                        help="Set to True for sandbox yaml generation")
    parser.add_argument(
        "--outputvars",
        type=argparse.FileType("w"),
        default="{}/jenkins_global_envvars.yaml".format(casc_d_dir),
        help="Optional custom location for jenkins_global_envvars.yaml",
    )
    return parser.parse_args()

def global_vars(global_var_file):
    with open(global_var_file) as myfile:
        for line in myfile:
            name, var = line.partition("=")[::2]
            varstripped = var.strip()
            kvlist.append({"key": name, "value": varstripped})
    output.update({'jenkins':
                   {'globalNodeProperties':
                       [{'envVars':envdict}]
                   }
                  })
    yaml.dump(output, parsed_args.outputvars)


parsed_args = parse_arguments()
path = (parsed_args.path)
global_var_file = ("{}/global-vars-production.sh".format(parsed_args.path))
if parsed_args.sandbox:
    global_var_file = ("{}/global-vars-sandbox.sh".format(parsed_args.path))

global_vars(global_var_file)
