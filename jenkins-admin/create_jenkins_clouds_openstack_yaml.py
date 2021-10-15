#!/usr/bin/env python
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
"""Create JCasC yaml file for the given Openstack cloud config"""

import argparse
import configparser
import glob
import os

from jinja2 import Template

# Template section
lookuptable = {
    "acumos-highcpu-4-avx": "c720c1f8-62e9-4695-823d-f7f54db46c86",
    "lf-highcpu-2": "1051d06a-61ea-45e3-b9b4-93de92880b27",
    "lf-highcpu-4": "35eb8e11-490f-4d1a-9f19-76091fc04547",
    "lf-highcpu-8": "68af673f-54ee-4255-871c-158c18e4f643",
    "lf-standard-1": "7d76cbb0-f547-4c2c-beaf-554f33832721",
    "lf-standard-2": "ef454088-7839-42a0-bf23-5e0ab6386a27",
    "lf-standard-4": "bd74e1e6-c2ed-475b-ab3f-2ce13936a215",
    "lf-standard-8": "32d74024-8418-41b6-9675-b77816748148",
    "odl-highcpu-2": "def1b86f-b7f8-4943-b430-4a0599170006",
    "odl-highcpu-4": "0c8ec795-2ff8-4623-98cf-b4c1d92bb37c",
    "odl-highcpu-8": "458d6499-e2c8-4580-aa88-a4a04a33ee25",
    "odl-standard-1": "35800a3f-0c69-428d-b5cb-136d17d46c48",
    "odl-standard-2": "8ead227a-acfe-4290-be70-fbab92e6dd2f",
    "odl-standard-4": "f76fb18d-d5fb-4175-95c1-b29d8039d102",
    "odl-standard-8": "ba38b1af-4f87-4e4e-860e-94e8329d0d78",
    "v1-standard-1": "bbcb7eb5-5c8d-498f-9d7e-307c575d3566",
    "v1-standard-2": "ca2a6e9c-2236-4107-8905-7ae9427132ff",
    "v1-standard-4": "5cf64088-893b-46b5-9bb1-ee020277635d",
    "v1-standard-8": "6eec77b4-2286-4e3b-b3f0-cac67aa2c727",
    "v1-standard-16": "2f8730dd-7688-4b72-a512-99fb9a482414",
    "v1-standard-32": "0da688af-bb0c-4116-a158-cbf37240a8b1",
    "v1-standard-48": "69471d69-61fb-40dd-bdf3-e6b7f4e6daa3",
    "v1-standard-64": "0c1d9008-f546-4608-9e8f-f8bdaec8dddd",
    "v1-standard-96": "5741c775-92a4-4488-bd77-dd7b08e2be81",
    "v1-standard-128": "e82d0a5b-8031-4526-9a5d-a15f7b4d48ff",
    "v2-highcpu-1": "c04abb7a-2b61-4ed3-8ce8-6c40ad9df750",
    "v2-highcpu-2": "03bdf34e-8905-46bc-a4b9-8dbf94b6e06d",
    "v2-highcpu-4": "3b72e578-7875-4e0e-91b7-71ed292f3ca2",
    "v2-highcpu-8": "221de281-95ec-414f-8e42-c86c9e0b318d",
    "v2-highcpu-16": "ddd6863a-ef4f-475c-9aee-61d46898651d",
    "v2-highcpu-32": "21dfb8a3-c472-4a2c-a8e1-4da8de415ff8",
    "v2-standard-1": "52a01f6b-e660-48b5-8c06-5fb2a0fab0ec",
    "v2-standard-2": "ac2c4d17-8d6f-4e3c-a9eb-57c155f0a949",
    "v2-standard-4": "d9115351-defe-4fac-986b-1a1187e2c31c",
    "v2-standard-8": "e6fe2e37-0e38-438c-8fa5-fc2d79d0a7bb",
    "v2-standard-16": "9e4b01cd-6744-4120-aafe-1b5e17584919",
    "v2-standard-360": "f0d27f44-a410-4f0f-9781-d722f5b5489e",
    "v3-standard-1": "555dff3a-7ec2-437e-bfc7-5a00113a304d",
    "v3-standard-2": "d6906d2a-e83f-42be-b33e-fbaeb5c511cb",
    "v3-standard-4": "5f1eb09f-e764-4642-a16f-a7230ec025e7",
    "v3-standard-6": "e145dc6b-7560-4633-ab6e-430028fd877f",
    "v3-standard-8": "47d3707a-c6c6-46ea-a15b-095e336b1edc",
    "v3-standard-16": "8587d458-69de-4fc5-be51-c5e671bc35d5",
    "v3-standard-20": "6baabd68-258c-4fdc-b0ba-5a77c5b89c21",
    "v3-standard-24": "cec3e6ff-667e-431c-9c14-ba7c1d9b4cc2",
    "v3-standard-32": "3e01b39f-45a9-4b7b-b6dc-14378433dc36",
    "v3-standard-48": "06a0e8b7-949a-439d-a185-208ae9e645b2",
    "v3-standard-64": "402a2759-cc01-481d-a8b7-2c7056f153f7",
    "v3-standard-96": "883b0564-dec6-4e51-88c7-83d86994fcf0",
    "v3-starter-1": "4d2a0d31-ebe9-4b99-a6d1-96c075b6c239",
    "v3-starter-2": "b542cedb-d3b4-4446-a43f-5416711440ee",
    "v3-starter-4": "5f93acce-e8dc-482b-9118-134728a77aa8",
    "v3-starter-6": "c5a671a2-2db5-4ffe-b681-ff77ec18bbe5",
    "v3-starter-8": "35c0ddb3-4dd8-478c-887c-34620851a66a",
    "v3-starter-16": "595dd716-6c7a-4365-9020-2ff10796e29c",
    "v3-starter-20": "3e8f788c-50ed-48c5-875e-5dfb3814d1f6",
    "v3-starter-24": "eb1af7f9-6b54-4780-a7e6-f76813106227",
    "v3-starter-32": "15949005-7952-4e93-be69-ca89dab5b884",
    "v3-starter-48": "94eb4cec-3840-4171-ad50-a8bce2757d11",
    "v3-starter-64": "4a6e52a2-8f64-4632-adde-72f81616d4f9",
    "v3-starter-96": "8e7205fc-3ec7-456c-bff0-e38609e415c1",
}
maintemplate = """\
---
jenkins:
  clouds:
    - openstack:
        credentialsId: {{ cloud_credential_id }}
        endPointUrl: {{ cloud_url }}
        ignoreSsl: {{ cloud_ignore_ssl }}
        name: {{ cloud_name }}
        slaveOptions:
          availabilityZone: {{ availability_zone }}
          bootSource:
            volumeFromImage:
              name: {{ image_name }}
              volumeSize: {{ volume_size }}
          fsRoot: {{ fs_root }}
          hardwareId: {{ hardware_id }}
{%- if is_sandbox is defined %}
          instanceCap: {{ sandbox_cap }}
{%- else %}
          instanceCap: {{ instance_cap }}{% endif %}
          keyPairName: {{ key_pair_name }}
          launcherFactory:
            ssh:
              credentialsId: {{ key_pair_name }}
          networkId: {{ network_id }}
          retentionTime: {{ retention_time }}
          userDataId: {{ user_data_id }}
        templates:
"""
machinetemplate = """\
          - labels: {{ labels }}
            name: {{ name_prefix }}-{{ agent_name }}
            slaveOptions:
              bootSource:
                {{ image_type }}:
                  name: {{ image_name }}
{%- if image_type == "volumeFromImage"  %}
                  volumeSize: {{ volume_size }}{% endif %}
{%- if hardware_id  %}
              hardwareId: {{ hardware_id }}{% endif %}
{%- if instance_cap %}
              instanceCap: {{ instance_cap }}{% endif %}
{%- if num_executors %}
              numExecutors: {{ num_executors }}{% endif %}
{%- if retention_time %}
              retentionTime: {{ retention_time }}
{%- else %}
              retentionTime: 0{% endif %}
"""
footertemplate = """\
        zone: {{ cloud_zone}}
"""

# Command line args section
def dir_path(path):
    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f"readable_dir: {path} is not a valid path")

def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Create JCasC yaml from path to Jenkins config dir.")

    parser.add_argument("--path", type=dir_path,
                        help="Path to jenkins-config directory")
    parser.add_argument("--name", type=str,
                        help="Cloud name (e.g \"cattle\")")

    parser.add_argument(
        "-s", "--sandbox",
        help="Configuration is being created for a sandbox",
        dest="sandbox", action="store_true"
    )

    return parser.parse_args()

parsed_args = parse_arguments()
path = (parsed_args.path)
path = ("{}**/*.cfg".format(path))

# Sandbox switch section
section_cloud = {}
name_prefix = "prd"
if parsed_args.sandbox:
    name_prefix = "snd"
    section_cloud.update(is_sandbox=True)

# Config parser from merged files section
def read_config(filename):
    shortname = os.path.basename(filename)
    header_name = os.path.splitext(shortname)[0]
    with open(filename, "r", encoding="utf_8") as config_file:
        config.read_file(add_section_header(config_file, header_name), source=filename)
    return config

# Cfg files are not real ini files, need to add section headers.
def add_section_header(properties_file, header_name):
    yield "[{}]\n".format(header_name)
    for line in properties_file:
        yield line

config = configparser.ConfigParser()
for filename in glob.iglob(path, recursive=True):
    # config_parser_merged is the configparser object with all the configs from *.cfg
    config_parser_merged = read_config(filename)

# Global cloud config section
cloud_config = (config.items("cloud"))
name = parsed_args.name
cloud_config_final = (*cloud_config, ("cloud_name", name))

for index, _ in enumerate(cloud_config_final):
    key = cloud_config_final[index][0]
    value = cloud_config_final[index][1]
    if value in lookuptable.keys():
        value = lookuptable[value]
    section_cloud[key] = value

j2_template = Template(maintemplate)
print(j2_template.render(section_cloud))


# All machines section
for section in config_parser_merged.sections():
    if section != "cloud":
        machine = (config.items(section))
        section_all_machines = {}
        for index, _ in enumerate(machine):
            key = machine[index][0]
            value = machine[index][1]
            if value in lookuptable.keys():
                value = lookuptable[value]
            section_all_machines[key] = value

        if "volume_size" not in section_all_machines:
            section_all_machines.update(image_type="image")
        else:
            section_all_machines.update(image_type="volumeFromImage")

        # Naming and labels
        section_all_machines.update(agent_name=section)
        if "labels" not in section_all_machines:
            # "section" is the name of the cloud agent, which is the default label
            section_all_machines.update(labels=section)
        elif section not in section_all_machines["labels"]:
            labels = section + " " + section_all_machines["labels"]
            section_all_machines.update(labels=labels)

        j2_template = Template(machinetemplate)
        section_all_machines.update(name_prefix=name_prefix)
        print(j2_template.render(section_all_machines))


# Footer section
j2_template = Template(footertemplate)
print(j2_template.render(section_cloud))
