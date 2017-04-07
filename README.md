# Global JJB

The purpose of this repository is store generically defined reusable JJB
templates that can be deployed across LF projects.

The following variables are necessary to be defined in the Jenkins server as
global environment variables as scripts in this repo expect these variables to
be available.

For example:
```
GIT_URL=ssh://jenkins-$SILO@git.opendaylight.org:29418
JENKINS_HOSTNAME=jenkins092
LOGS_SERVER=https://logs.opendaylight.org
NEXUS_URL=https://nexus.opendaylight.org
SILO=releng
```
