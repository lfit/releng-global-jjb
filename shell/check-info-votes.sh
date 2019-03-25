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

  #On the fly info file from the tsc members in INFO-master.yaml
  project="$(echo $GERRIT_URL | awk -F"." '{print $2}')"
  curl -o /tmp/INFO-master.yaml "https://gerrit.linuxfoundation.org/infra/gitweb?p=releng/info-master.git;a=blob_plain;f=INFO-master.yaml;hb=HEAD"
  printf -- "---\ncommitters:\n" > /tmp/INFO.yaml
  for x in $(niet ".$project.tsc" /tmp/INFO-master.yaml); do echo "    - id: "$x >> /tmp/INFO.yaml; done

  echo "Generated TSC INFO file:"
  cat /tmp/INFO.yaml

  echo "Checking votes:"
  lftools infofile check-votes INFO.yaml "$GERRIT_URL" "$ref" --tsc /tmp/INFO.yaml

fi
