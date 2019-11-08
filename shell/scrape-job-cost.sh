#! /bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

#############################################################################
#

# This script will be run on the projects 'nexus' server.  It will
# find all the job cost files (job_name/job_num/cost.csv) and append
# them to the project cost file (cost-YYYY.csv) located in the project
# directory. It will then delete all the job cost files.

#
#############################################################################

set -eufo pipefail

if [[ $# != 1 ]]; then
    echo "usage: $(basename $0) project_dir"
    exit 1
fi

# The Project Dir is top-level directory that will contain the job directories
# and the project cost file. (cost-YYYY.csv)
proj_dir=$1

# Do I want select the project cost file base on date from CSV record?
# Or do it based on the that date this script was run?
project_cost_file=cost-$(date +'%Y').csv

cd $proj_dir

if [[ ! -f $project_cost_file ]]; then
   echo "Creating New Project Cost File: $project_cost_file"
   touch $project_cost_file
fi

echo -n "Appending... "
find . -maxdepth 3 -name cost.csv > cost-file-list
num=$(wc -l < cost-file-list)
sort --field-separator=',' --key=3 -o cost-file-list cost-file-list
xargs cat < cost-file-list >> $project_cost_file
xargs rm -f < cost-file-list

echo -n "Sorting... "
# Sort the file by 'date' (column 3) The date format was selected to support
# sorting.
sort --field-separator=',' --key=3 -o $project_cost_file $project_cost_file

echo "Added $num cost entries"
