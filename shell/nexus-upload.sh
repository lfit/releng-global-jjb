#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 The LMinux Foundation <matthew.watkins@linuxfoundation.org>
# Uncomment to enable debugging
# set -vx
# Initialise variables
DIRECTORY="."
FILE_EXTENSION=""
# Count file upload successes/failures
SUCCESSES="0"; FAILURES="0"
# Shared functions
show_help() {
    # Command usage help
    cat << EOF
Usage: ${0##*/} [-h] [-u user] [-p password] [-s upload-url] [-e extensions] [-d folder]
    -h  display this help and exit
    -u  username (or export variable NEXUS_USERNAME)
    -p  password (or export variable NEXUS_PASSWORD)
    -s  upload URL (or export variable NEXUS_URL)
        e.g. https://nexus3.o-ran-sc.org/repository/datasets/
    -e  file extensions to match, e.g. csv, txt
    -d  local directory hosting files/content to be uploaded
EOF
}
error_help() {
    show_help >&2
    exit 1
}
transfer_report() {
    echo "Successes: $SUCCESSES   Failures: $FAILURES"
    if [ "$FAILURES" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}
curl_upload() {
    FILE="$1"
    echo "Sending: ${FILE}"
    # echo "Running: $CURL --fail [CREDENTIALS] --upload-file $FILE $NEXUS_URL"
    if ("$CURL" --fail -u "$CREDENTIALS" --upload-file "$FILE" "$NEXUS_URL"); then #> /dev/null 2>&1
        SUCCESSES=$((SUCCESSES+1))
    else
        FAILURES=$((FAILURES+1))
    fi
}
process_files() {
    for FILE in "${UPLOAD_FILES_ARRAY[@]}"; do
        curl_upload "$FILE"
    done
}
# Validate/check arguments and variables
CURL=$(which curl)
if [ ! -x "$CURL" ];then
    echo "CURL was not found in your PATH"; exit 1
fi
while getopts hu:p:s:d:e: opt; do
    case $opt in
        u)  NEXUS_USERNAME="$OPTARG"
            ;;
        p)  NEXUS_PASSWORD="$OPTARG"
            ;;
        s)  NEXUS_URL="$OPTARG"
            ;;
        e)  FILE_EXTENSION="$OPTARG"
            ;;
        d)  DIRECTORY="$OPTARG"
            if [ ! -d "$DIRECTORY" ]; then
                echo "Error: specified directory invalid"; exit 1
            fi
            ;;
        h|?)
            show_help
            exit 0
            ;;
        *)
            error_help
        esac
done
shift "$((OPTIND -1))"   # Discard the options
# Gather location of files to upload (in an array)
mapfile -t UPLOAD_FILES_ARRAY < <(find "$DIRECTORY" -name "*$FILE_EXTENSION" -type f -print )
if [ "${#UPLOAD_FILES_ARRAY[@]}" -ne 0 ]; then
    echo "Files found to upload: ${#UPLOAD_FILES_ARRAY[@]}"
    # echo "Files matching pattern:"  # Uncomment for debugging
    # echo "${UPLOAD_FILES_ARRAY[@]}"  # Uncomment for debugging
else
    echo "Error: no files found to process matching pattern"
    exit 1
fi
if [ -z "$NEXUS_URL" ]; then
    echo "ERROR: Specifying the upload/repository URL is mandatory"; exit 1
else
    if  [[ ! "$NEXUS_URL" == "http://"* ]] && \
        [[ ! "$NEXUS_URL" == "https://"* ]]; then
        echo "Error: Nexus server must be specified as a URL"; exit 1
    fi
fi
# Prompt for credentials if not specified explicitly or present in the shell environment
if [ -z "$NEXUS_USERNAME" ]; then
    echo -n "Enter username: "
    read -r NEXUS_USERNAME
    if [[ -z "$NEXUS_USERNAME" ]]; then
        echo "ERROR: Username cannot be empty"; exit 1
    fi
fi
if [ -z "$NEXUS_PASSWORD" ]; then
    echo -n "Enter password: "
    read -s -r NEXUS_PASSWORD  # Does not echo to terminal/console
    echo ""
    if [[ -z "$NEXUS_PASSWORD" ]]; then
        echo "ERROR: Password cannot be empty"; exit 1
    fi
fi
CREDENTIALS="$NEXUS_USERNAME:$NEXUS_PASSWORD"
# Main script entry point
echo "Uploading to: $NEXUS_URL"
process_files
transfer_report
