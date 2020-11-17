#!/usr/bin/env python

import argparse
import configparser
import glob
import os
import sys

from jinja2 import Environment
from jinja2 import FileSystemLoader
from jinja2 import Template

#Template section
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
    "v2-standard-360": "f0d27f44-a410-4f0f-9781-d722f5b5489e"
}
maintemplate = """\
---
jenkins:
  clouds:
    - openstack:
        credentialsId: {{ cloud_credential_id }}
        endPointUrl: {{ cloud_url }}
        ignoreSsl: {{ cloud_ignore_ssl }}
        name: "cattle"
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
            name: {{ name_prefix }}-{{ labels }}
            slaveOptions:
              bootSource:
                volumeFromImage:
                  name: {{ image_name }}
                  volumeSize: {{ volume_size }}
{%- if hardware_id  %}
              hardwareId: {{ hardware_id }}{% endif %}
{%- if instance_cap %}
              instanceCap: {{ instance_cap }}{% endif %}
{%- if num_executors %}
              numExectorts: {{ num_executors }}{% endif %}
{%- if retention_time %}
              retentionTime: {{ retention_time }}
{%- else %}
              retentionTime: 0{% endif %}
"""
footertemplate = """\
        zone: {{ cloud_zone}}
"""

#Command line args section
def dir_path(path):
    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f"readable_dir:{path} is not a valid path")

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='Create jcasc yaml from path to jenkins config dir.')


    parser.add_argument('--path', type=dir_path,
                        help="Path to jenkins-admin directory")

    parser.add_argument(
        "-s", "--sandbox",
        help = "Is configuration being created for a sandbox",
        dest = "sandbox", action = "store_true"
    )

    return parser.parse_args()

parsed_args = parse_arguments()
path = (parsed_args.path)
path = ("{}**/*.cfg".format(path))

#sandbox switch section
section_cloud = {}
name_prefix = "prd"
if parsed_args.sandbox:
    name_prefix = "snd"
    section_cloud.update(is_sandbox=True)

#Config parser from merged files section
class Iterfiles:
    def __init__(self, filename):
        self.filename = filename

    def iterf(self):
        shortname = os.path.basename(filename)
        shortname1 = os.path.splitext(shortname)[0]
        return (self.filename, shortname1)

class Openfile:
    def __init__(self, filename, shortname1):
        self.filename = filename
        self.shortname1 = shortname1
    def openf(self):
        file = open(self.filename, encoding="utf_8")
        config.read_file(add_section_header(file, self.shortname1), source=self.filename)
        return config

#cfg files are not real ini files, need to add section headers.
def add_section_header(properties_file, header_name):
    yield '[{}]\n'.format(header_name)
    for line in properties_file:
        yield line

config = configparser.ConfigParser()
for filename in glob.iglob(path, recursive=True):
    #This just returns the filename you sent it and a shortname
    # dumb but just messing around with classes.
    r1 = Iterfiles(filename)
    r3 = r1.iterf()
    #now i send the file name and the shortname to Openfile class
    #which builds up a big configparser with sections divided by shortname
    r5 = Openfile(r3[0], r3[1])
    #config_parser_merged is the configparser object with all the configs from *.cfg
    config_parser_merged = r5.openf()


# Global cloud config section
for section in config_parser_merged.sections():
    if section == "cloud":
        final = (config.items(section))


for index, _ in enumerate(final):
    a = final[index][0]
    b = final[index][1]
    for x, y in lookuptable.items():
        if b == x:
            b = y
    section_cloud[a] = b

j2_template = Template(maintemplate)
print(j2_template.render(section_cloud))


# All machines section
for section in config_parser_merged.sections():
    if section != "cloud":
        machine = (config.items(section))
        section_all_machines = {}
        for index, _ in enumerate(machine):
            a = machine[index][0]
            b = machine[index][1]
            for x, y in lookuptable.items():
                if b == x:
                    b = y
            #a = format(a)
            section_all_machines[a] = b


        #Default volume size of 10
        if not "volume_size" in section_all_machines:
            section_all_machines.update(volume_size="10")
        if not "labels" in section_all_machines:
            print("LABELS not Set in builder config")
            print(section_all_machines)
            exit(1)


        j2_template = Template(machinetemplate)
        section_all_machines.update(name_prefix=name_prefix)
        print(j2_template.render(section_all_machines))


#Footer section
j2_template = Template(footertemplate)
print(j2_template.render(section_cloud))
