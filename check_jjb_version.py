# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2018 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
"""Ensures that the jjb-version in tox and jjb/lf-ci-jobs.yaml match."""

__author__ = 'Thanh Ha'


import os
import re
import sys


def check_jjb_version(tox_file, releng_jobs_file):
    with open(tox_file, 'r') as _file:
        for num, line in enumerate(_file, 1):
            if re.search('jenkins-job-builder==', line):
                jjb_version_tox = line.rsplit('==', 1)[1].strip()
                break

    with open(releng_jobs_file, 'r') as _file:
        for num, line in enumerate(_file, 1):
            if re.search('jjb-version: ', line):
                jjb_version = line.rsplit(':', 1)[1].strip()
                break

    print('JJB version in jjb/lf-ci-jobs.yaml: {}'.format(jjb_version))
    print('JJB version in tox.ini: {}'.format(jjb_version_tox))

    if jjb_version != jjb_version_tox:
        print('ERROR: JJB version in jjb/lf-ci-jobs.yaml and tox.ini MUST match.')
        sys.exit(1)


if __name__ == "__main__":
    check_jjb_version('tox.ini', os.path.join('jjb', 'lf-ci-jobs.yaml'))
