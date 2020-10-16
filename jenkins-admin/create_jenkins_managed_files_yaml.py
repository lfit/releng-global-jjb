#!/usr/bin/env python

"""Convert Managed Config files to JCasC YAML"""

from pprint import pformat

import argparse
import configparser
import logging
import os
import sys

logging.basicConfig(format="%(asctime)s %(levelname)s %(message)s",
    level=logging.INFO)

def dir_path(path):
    """Validate that path provided exists"""

    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(
                f"readable_dir:{path} is not a valid path")

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

def _main():
    args = getArgs()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if args.quiet:
        logging.getLogger().setLevel(logging.ERROR)

    output = {}

    for (dirpath, dirnames, filenames) in os.walk(args.path):
        logging.info("\n" + pformat((dirpath, dirnames, filenames)))

if __name__ == "__main__":
    sys.exit(_main())
