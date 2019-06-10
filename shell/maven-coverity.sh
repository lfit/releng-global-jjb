#!/bin/bash

# Copyright 2019 Samsung Electronics Co., Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -Eeuxo pipefail
PS4='+['$(readlink -f "$0")' ${FUNCNAME[0]%main}#$LINENO] '

echo '---> maven-coverity.sh'

#-----------------------------------------------------------------------------
# Get Coverity Scan build tool

curl \
  --verbose \
  --silent \
  --show-error \
  --fail \
  --form "project=${COVERITY_PROJECT_NAME}" \
  --form "token=${COVERITY_TOKEN}" \
  --output 'coverity_tool.tgz' \
  'https://scan.coverity.com/download/linux64'

tar \
  --extract \
  --gunzip \
  --file='coverity_tool.tgz'

COVERITY_BUILD_TOOL_DIRECTORY=$(
  head -1 <( \
    tar \
      --list \
      --gunzip \
      --file='coverity_tool.tgz'
  )
)
COVERITY_BINARY_DIRECTORY="${COVERITY_BUILD_TOOL_DIRECTORY}bin"
test -d "${COVERITY_BINARY_DIRECTORY}" \
  || exit 1
export PATH="${PATH}:${COVERITY_BINARY_DIRECTORY}"

rm 'coverity_tool.tgz'

#-----------------------------------------------------------------------------
# Build

export MAVEN_OPTS

cov-build \
  --dir 'cov-int' \
  "${MVN}" clean install \
    --errors \
    --global-settings "${GLOBAL_SETTINGS_FILE}" \
    --settings "${SETTINGS_FILE}" \
    ${MAVEN_OPTIONS:=} \
    ${MAVEN_PARAMS:=}

cov-import-scm \
  --dir 'cov-int' \
  --scm 'git'

#-----------------------------------------------------------------------------
# Submit results to Coverity service

tar \
  --create \
  --gzip \
  --file='results.tgz' \
  'cov-int'

curl \
  --verbose \
  --silent \
  --show-error \
  --fail \
  --form "project=${COVERITY_PROJECT_NAME}" \
  --form "email=${COVERITY_USER_EMAIL}" \
  --form "token=${COVERITY_TOKEN}" \
  --form 'file=@results.tgz' \
  --form "version=${GIT_COMMIT:0:7}" \
  --form "description=${GIT_BRANCH}" \
  'https://scan.coverity.com/builds'

#-----------------------------------------------------------------------------

exit 0
