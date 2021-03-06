#!/usr/bin/env python

"""Convert Managed Config files to JCasC YAML"""

from pprint import pformat

import argparse
import configparser
import logging
import os
import ruamel.yaml
import sys

yaml = ruamel.yaml.YAML()
yaml.allow_duplicate_keys = True
yaml.preserve_quotes = True

logging.basicConfig(format="%(asctime)s %(levelname)s %(message)s",
    level=logging.INFO)

def dir_path(path):
    """Validate that path provided exists"""

    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(
                "'%s' is not a valid path" % path)

def getArgs():
    """Parse the commandline arguments"""

    parser = argparse.ArgumentParser(
        description = __doc__,
        formatter_class = argparse.ArgumentDefaultsHelpFormatter
    )

    # default argument options
    parser.add_argument(
        "-o", "--output", help = "Output file",
        type = argparse.FileType("w")
    )
    parser.add_argument(
        "-p", "--path", help = "Path to configuration files to read",
        type = dir_path, required = True
    )
    parser.add_argument(
        "-q", "--quiet", help = "Run quiet", dest = "quiet",
        action = "store_true"
    )
    parser.add_argument(
        "-s", "--sandbox",
        help = "Is configuration being created for a sandbox",
        dest = "sandbox", action = "store_true"
    )
    parser.add_argument(
        "-v", "--verbose", dest = "verbose", action = "store_true",
        help = "Enable verbose (debug) logging"
    )

    return parser.parse_args()

def processConfig(path, subpath, files, sandbox):
    """Process the configuration file and return the configuration object"""

    logging.debug("In processConfig")
    logging.debug("\n" + pformat(path) + "\n" + pformat(subpath) + "\n" + pformat(files))

    ret = { subpath[0]:
            {
                "id": subpath[1]
            }
        }

    for config in files:
        # skip all hidden files
        if '.' in config[0]:
            continue

        if '.yaml' in config:
            loadYaml = False
            # Only load credential mappings files if the file matches
            # the type of jenkins silo (ie production or sandbox)
            if 'CredentialMappings' in config:
                if sandbox and 'sandbox' in config:
                    loadYaml = True
                elif not sandbox and 'sandbox' not in config:
                    loadYaml = True
            else:
                loadYaml = True

            if loadYaml:
                stream = open(os.path.join(path, config), 'r')
                ret[subpath[0]].update(yaml.load(stream))

        if 'content' in config:
            stream = open(os.path.join(path, config), 'r')
            ret[subpath[0]].update({'content': stream.read()})

            # custom files need to have ${ prefixed with ^ for some reason
            if 'custom' in subpath[0] or 'properties' in subpath[0]:
                ret[subpath[0]]['content'] = \
                        ret[subpath[0]]['content'].replace('${', '^${')

    return ret

def _main():
    args = getArgs()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if args.quiet:
        logging.getLogger().setLevel(logging.ERROR)

    output = { 'unclassified':
                { 'globalConfigFiles':
                    { 'configs': [] }
                }
            }

    configs = []

    pathsplit = args.path.split('/')

    for (dirpath, dirnames, filenames) in os.walk(args.path):
        logging.debug("\n" + pformat((dirpath, dirnames, filenames)))

        curpath = [x for x in dirpath.split('/') if x not in pathsplit]
        if len(curpath) > 1:
            configs.append(processConfig(dirpath, curpath, filenames, args.sandbox))


    output['unclassified']['globalConfigFiles']['configs'] = configs

    if args.output:
        yaml.dump(output, args.output)
    else:
        yaml.dump(output, sys.stdout)

if __name__ == "__main__":
    sys.exit(_main())
