#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2015 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

# Increase limits
cat <<EOF > /etc/security/limits.d/jenkins.conf
jenkins         soft    nofile          16000
jenkins         hard    nofile          16000
EOF

cat <<EOF >/etc/sudoers.d/89-jenkins-user-defaults
Defaults:jenkins !requiretty
jenkins     ALL = NOPASSWD: ALL
EOF

cat <<EOSSH >> /etc/ssh/ssh_config
Host *
  ServerAliveInterval 60

# MPSF (Vexxhost)
Host 10.30.21*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# ODL (Vexxhost)
Host 10.30.170.* 10.30.171.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

# ONAP (Vexxhost)
Host 10.30.104.*
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOSSH

cat <<EOKNOWN >  /etc/ssh/ssh_known_hosts
github.com,192.30.253.112 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
[140.211.169.26]:29418,[git.opendaylight.org]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyRXyHEw/P1iZr/fFFzbodT5orVV/ftnNRW59Zh9rnSY5Rmbc9aygsZHdtiWBERVVv8atrJSdZool75AglPDDYtPICUGWLR91YBSDcZwReh5S9es1dlQ6fyWTnv9QggSZ98KTQEuE3t/b5SfH0T6tXWmrNydv4J2/mejKRRLU2+oumbeVN1yB+8Uau/3w9/K5F5LgsDDzLkW35djLhPV8r0OfmxV/cAnLl7AaZlaqcJMA+2rGKqM3m3Yu+pQw4pxOfCSpejlAwL6c8tA9naOvBkuJk+hYpg5tDEq2QFGRX5y1F9xQpwpdzZROc5hdGYntM79VMMXTj+95dwVv/8yTsw==
[gerrit.onap.org]:29418,[198.145.29.92]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyAKv0UzEhpGKP/rW+yHpngl32Ppr5Uy42coz/sYZYxbtpI+9yaMqfoBb06ktmt6kV7OCT/Sc0OpyWmpcR0d7KZHxx/LE/nm7Gi+xkNHhb9G+Hn6DagP4V+LS6x1YlUt2InLCb8g07+/n6rfxqCI6emIJYu9aTpDhaARb+mMX1xzJuoa4wp59Yr1mkKK8lXHKGnPCemyl9a0vSRY58b7ZWG/N8giNvqYeptslIF1E/MEI5AP6nx7EupiVulAUdboAnDSD0urt9zdE8KRjboghB7PHguil6/OZhbqOb/uEt/rGCHn+02pig1K/vjFvCqNErNgS6EKj0IkH+cU/vjV6j
[gerrit.opnfv.org]:29418,[198.145.29.81]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/jsHVV7453mz8D9tQp9t4gDZSYEnt7RTbm9dQCHvrjDxjKRaxCwFkEEF/wHgEm2DkiHLroRvcrJAN6aTH8SdMT4xpOIbD9iDw2ucHWjm3pJ0y4KlNcMnpg9uEWArwhR+pDWgxRCU77eCbCwv1ZEdqMfSgmYdO+MudNZXrldbgFAvsO1HbpwP/naCmUuYDfxlp3UCau19wR8BTKYGnROmQQXB5fSmNW7zrPsAdf7+rzktg1jp9JF7ss34T+gmxEigaC1WrpWRRlIsVTMHH3a9efcgJBS8sAcGRYMg5JRCArPP5u0dg6dXNqk8Zbd0CRpF72A9xVINRf7JZdea2yD+L
EOKNOWN

# To handle the prompt style that is expected all over the environment
# with how use use robotframework we need to make sure that it is
# consistent for any of the users that are created during dynamic spin
# ups
echo 'PS1="[\u@\h \W]> "' >> /etc/skel/.bashrc

# vim: sw=2 ts=2 sts=2 et :
