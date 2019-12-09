#! /bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2020 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

##############################################################################

# This script will be run on the projects Nexus server.  It will find all the
# job cost files (job_name/job_num/cost.csv) and append them to the project cost
# file (cost-YYYY.csv) located in the project directory. It will then delete all
# the job cost files.

# Because this file meant to be run by cron, I have restricted normal info
# logging messages on a single line. Error may be multi-line.
#
# Each cost file contains one or more CSV records in the following format:
#
#   JobName , BuildNumber , Date , InstanceType , Uptime , Cost1 , Cost2
#
#   Date format: '%Y-%m-%d %H:%M:%S'
#
##############################################################################
#
#  Testing/Validation
#
#  You can validate this script by running as yourself on the Nexus server. You
#  should not have write permission anywhere in the Project Directory. The
#  Annual Cost File from your test will be created/updated in:
#  ~/cost/$jenkins_server-$year.csv. If you run multiple times, duplicate
#  records will be created.
#
#  To enable debug set envionment variable DEBUG=true. If this is done on the
#  command-line, you  do not have to edit this file.
debug=${DEBUG:-false}
$debug && echo "DEBUG Enabled"
#
##############################################################################

set -eufo pipefail

function get-year-list()
{
    # Grab the years for each cost record use sort | uniq to get the
    # list of unique years found
    local list
    list=$(awk -F',' '{print $3}' "$cost_file_records" \
               | awk -F'-' '{print $1}' | sort | uniq)
    echo "$list"
}

###########  End of Function Definitions  ######################################

if [[ $# != 2 ]]; then
    echo "usage: $(basename "$0") production|sandbox project_dir"
    exit 1
fi

# The Project Dir is top-level directory that will contain the job directories
# which will contain the cost files (cost.csv)
jenkins_server=$1
proj_dir=$2

case $jenkins_server in
    production) ;;
    sandbox)    ;;
    *) echo "ERROR: invalid Jenkins Server: $jenkins_server"
       echo "Only valid values are: production & sandbox"
       exit 1
       ;;
esac

cost_file_records=/tmp/cost-file-records$$
cost_file_list=/tmp/cost-file-list$$
# The directory where the annual cost file will be located
cost_dir=~/cost
[[ -d $cost_dir ]] || mkdir $cost_dir

# The Project Directory for sandbox will get deleted periodically, so
# gracefully handle that
if [[ -d $proj_dir ]]; then
   cd "$proj_dir"
else
    echo  "$(date +'%Y-%m-%d %H:%M') No Project Directory, nothing to do"
    exit 0
fi

find . -maxdepth 3 -name cost.csv > $cost_file_list
xargs cat < $cost_file_list | \
    sort --field-separator=',' --key=3  > $cost_file_records
num_of_records=$(wc -l < $cost_file_records)
echo -n "$(date +'%Y-%m-%d %H:%M') Records: $num_of_records "

if [[ $num_of_records == 0 ]]; then
    echo "Nothing to do"
    set +f
    rm -rf /tmp/cost-file-* || true
    exit 0
fi

# Append each entry to the project cost file based on date
year_list=$(get-year-list)
for year in $year_list; do
    echo -n "cost-$year.csv: $(grep -Fc ",$year-" $cost_file_records) "
    grep -F ",$year-" $cost_file_records >>    \
         "$cost_dir/$jenkins_server-$year.csv"
done

# Rename the job cost files (make them hidden)
while read -r p; do
    job_dir=$(dirname "$p")
    $debug || (cd "$job_dir" ; mv cost.csv .cost.csv)
done < $cost_file_list

rm -r $cost_file_list $cost_file_records

echo -n "Sorting: "
# Sort the project cost file by 'date' (column 3)
for year in $year_list; do
    echo -n "cost-$year.csv "
    sort --field-separator=',' --key=3            \
         -o "$cost_dir/$jenkins_server-$year.csv" \
         "$cost_dir/$jenkins_server-$year.csv"
done

set +f
rm -rf /tmp/cost-file-* || true

# Keep track of time initally
echo "Complete $SECONDS Secs"
