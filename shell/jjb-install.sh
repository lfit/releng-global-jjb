#!/bin/bash
virtualenv $WORKSPACE/.virtualenvs/jjb
source $WORKSPACE/.virtualenvs/jjb/bin/activate
pip install --upgrade pip
pip install jenkins-job-builder=={jjb-version}
pip freeze
