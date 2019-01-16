#!/usr/bin/env python2
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
"""
List Release Repos
"""

import argparse
import yaml


class Repo(object):
    """Object representing a repo listed in the release file.

    Includes eq, hash, and ne methods so set comparisons work
    """

    def __init__(self, repo=None, ref=None, version=None):
        self.repo = repo
        self.ref = ref
        self.version = version

    def __repr__(self):
        if self.version:
            return "%s %s %s" % (self.repo, self.ref, self.version)
        elif self.ref:
            return "%s %s" % (self.repo, self.ref)
        return "%s" % self.repo

    def __eq__(self, obj):
        if isinstance(obj, Repo):
            return ((self.repo == obj.repo) and
                    (self.ref == obj.ref) and
                    (self.version == obj.version))
        return False

    def __ne__(self, obj):
        return (not self.__eq__(obj))

    def __hash__(self):
        return hash(self.__repr__())


def main():
    """Given a release yamlfile list the repos it contains"""

    parser = argparse.ArgumentParser()
    parser.add_argument('--file', '-f',
                        type=argparse.FileType('r'),
                        required=True)
    parser.add_argument('--names', '-n',
                        action='store_true',
                        default=False,
                        help="Only print the names of repos, "
                             "not their SHAs")
    parser.add_argument('--release', '-r',
                        type=str,
                        help="Only print"
                             "SHAs for the specified release")
    parser.add_argument('--branches', '-b',
                        action='store_true',
                        default=False,
                        help="Print Branch info")

    args = parser.parse_args()

    project = yaml.safe_load(args.file)

    if args.branches:
        list_branches(project, args)
    else:
        list_repos(project, args)


def list_repos(project, args):
    """List repositories in the project file"""

    lookup = project.get('releases', [])

    if 'releases' not in project:
        exit(0)
    repos = set()
    for item in lookup:
        repo, ref = next(iter(item['location'].items()))
        if args.names:
            repos.add(Repo(repo))
        elif args.release and item['version'] == args.release:
            repos.add(Repo(repo, ref))
        elif not args.release:
            repos.add(Repo(repo, item['version'], ref))
    for repo in repos:
        print(repo)


def list_branches(project, args):
    """List branches in the project file"""

    lookup = project.get('branches', [])

    if 'branches' not in project:
        exit(0)
    repos = set()
    for item in lookup:
        repo, ref = next(iter(item['location'].items()))
        if args.names:
            repos.add(Repo(repo))
        elif args.release and item['name'] == args.release:
            repos.add(Repo(repo, ref))
        elif not args.release:
            repos.add(Repo(repo, item['name'], ref))
    for repo in repos:
        print(repo)

if __name__ == "__main__":
    main()
