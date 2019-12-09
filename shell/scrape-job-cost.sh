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
# Because this file meant to be run by cron, I have restricts normal info
# logging messages on a single line.
#
#############################################################################

set -eufo pipefail

function get-year-list()
{
    # Grab the years for each cost record use sort | uniq to get the
    # list of unique years found
    local list
    list=$(awk -F',' '{print $3}' $cost_file_records \
               | awk -F'-' '{print $1}' | sort | uniq)
    echo $list
}

if [[ $# != 1 ]]; then
    echo "usage: $(basename $0) project_dir"
    exit 1
fi

# The Project Dir is top-level directory that will contain the job directories
# and the project cost file. (cost-YYYY.csv)
proj_dir=$1

cost_file_list=/tmp/cost-file-list
cost_file_records=/tmp/cost-file-records

cd $proj_dir

find . -maxdepth 3 -name cost.csv > $cost_file_list
xargs cat < $cost_file_list |\
    sort --field-separator=',' --key=3  > $cost_file_records
num_of_records=$(wc -l < $cost_file_records)
echo -n "$(date +'%Y-%m-%d %H:%M') Records: $num_of_records "

if [[ $num_of_records == 0 ]]; then
    echo "Nothing to do"
    exit 0
fi

# Append each entry to the project cost file based on date
year_list=$(get-year-list)
for year in $year_list; do
    echo -n "cost-$year.csv: $(fgrep ",$year-" $cost_file_records | wc -l) "
    fgrep ",$year-" $cost_file_records >> cost-$year.csv
done

# Delete all the job cost files
xargs rm -f < $cost_file_list

rm -r $cost_file_list $cost_file_records

echo -n "Sorting: "
# Sort the project cost file by 'date' (column 3)
for year in $year_list; do
    echo -n "cost-$year.csv "
    sort --field-separator=',' --key=3 -o cost-$year.csv cost-$year.csv
done

# Keep track of time initally
echo "Complete $SECONDS Secs"
