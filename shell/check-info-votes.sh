#!/bin/bash -l
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2019 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> check-info-votes.sh"
set -xe -o pipefail

ref=$(echo "$GERRIT_REFSPEC" | awk -F"/" '{ print $4 }')

# For OPNFV
if [[ $NODE_NAME =~ "lf-build" ]]; then
  pip install --user niet
  pip install --user lftools
  pip install --user lftools[nexus]
  pip install --user jsonschema

  lftools infofile check-votes INFO.yaml "$GERRIT_URL" "$ref"

# For All other projects.
else

  if [ -d "/opt/pyenv" ]; then
      echo "---> Setting up pyenv"
      export PYENV_ROOT="/opt/pyenv"
      export PATH="$PYENV_ROOT/bin:$PATH"
  fi
  PYTHONPATH=$(pwd)
  export PYTHONPATH
  pyenv local 3.6.4
  export PYENV_VERSION="3.6.4"

  pip3 install --user niet
  pip3 install --user lftools
  pip3 install --user lftools[nexus]
  pip3 install --user jsonschema

  #We need to get the TSC info file somehow...
  lftools infofile check-votes INFO.yaml "$GERRIT_URL" "$ref" --tsc /tmp/INFO.yaml

fi
