#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
"""
Verify YAML Schema
"""
import argparse
import logging
import jsonschema
import yaml

LOADER = yaml.CSafeLoader if yaml.__with_libyaml__ else yaml.SafeLoader


def main():
    """
    Parse arguments and verify YAML
    """
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument('--yaml', '-y', type=str, required=True)
    parser.add_argument('--schema', '-s', type=str, required=True)

    args = parser.parse_args()

    with open(args.yaml) as _:
        yaml_file = yaml.load(_, Loader=LOADER)

    with open(args.schema) as _:
        schema_file = yaml.load(_, Loader=LOADER)

    # Load the schema
    validation = jsonschema.Draft4Validator(
        schema_file,
        format_checker=jsonschema.FormatChecker()
    )

    # Look for errors
    errors = 0
    for error in validation.iter_errors(yaml_file):
        errors += 1
        logging.error(error)
    if errors > 0:
        raise RuntimeError("%d issues invalidate the release schema" % errors)


if __name__ == "__main__":
    main()
