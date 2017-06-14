#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# This script publishes packages (rpms/debs) or any file to Nexus hosted
# maven2 repository.
#
# $NEXUS_URL          :  Jenkins global variable should be defined.
# $REPO_ID            :  Provided by a job parameter.
# $UPLOAD_FILES_PATH  :  Provided by a job parameter.

# Ensure we fail the job if any steps fail.
set -eu -o pipefail

TMP_FILE="$(mktemp)"

UPLOAD_FILES_PATH=${UPLOAD_FILES_PATH:-"$WORKSPACE/archives/upload_files"}
mkdir -p "$UPLOAD_FILES_PATH"
OS=$(facter operatingsystem)

while IFS="" read -r file
do

    case "$OS" in
        Ubuntu)
            basefile=$(basename -s .deb "$file")

            # get artifact_id and version information from file.
            artifact_id=$(echo "$basefile" | cut -f 1 -d '_')
            version=$(echo "$basefile" | cut -f 2- -d '_')
            classifier="deb"
            ;;

        CentOS)
            # get artifact_id and version information from file.
            artifact_id=$(rpm -qp --queryformat="%{name}" "$file")

            if grep -qE '\.s(rc\.)?rpm' <<<"$file"; then
                rpmrelease=$(rpm -qp --queryformat="%{release}.src" "$file")
            else
                rpmrelease=$(rpm -qp --queryformat="%{release}.%{arch}" "$file")
            fi

            version=$(rpm -qp --queryformat="%{version}" "$file")
            version+="-$rpmrelease"
            classifier="rpm"
            ;;

        * )
            echo "ERROR: Unrecognized OS \"$OS\"." 1>&2
            exit 1
            ;;
    esac

    lftools deploy maven-file "$NEXUS_URL" \
                              "$REPO_ID" \
                              "$REPO_ID" \
                              "$file" \
                              "-b $MVN" \
                              "-a $artifact_id" \
                              "-c $classifier" \
                              "-v $version" | tee "$TMP_FILE"
done < <(find "$UPLOAD_FILES_PATH" -type d -name "*")

# Store repo info to a file in archives
mkdir -p "$WORKSPACE/archives"
cp "$TMP_FILE" "$WORKSPACE/archives/deploy-maven-file.log"

# Cleanup
rm "$TMP_FILE"

# Cleanup rpm/deb files
rm -rf "$UPLOAD_FILES_PATH"
