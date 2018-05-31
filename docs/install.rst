#######
Install
#######

global-jjb requires configuration in 2 places; ``Jenkins`` and the
``ci-management`` repository.

Jenkins
=======

Jenkins needs to be configured with ``environment variables`` and ``plugins``
as needed by the jobs provided by global-jjb.

Install Jenkins plugins
-----------------------

Before we can begin the necessary Jenkins plugins need to be installed.

**Required**

- `Config File Provider <https://plugins.jenkins.io/config-file-provider>`_
- `Description Setter <https://plugins.jenkins.io/description-setter>`_
- `Environment Injector Plugin <https://plugins.jenkins.io/envinject>`_
- `Git plugin <https://plugins.jenkins.io/git>`_
- `Post Build Script <https://plugins.jenkins.io/postbuildscript>`_
- `SSH Agent <https://plugins.jenkins.io/ssh-agent>`_
- `Workspace Cleanup <https://plugins.jenkins.io/ws-cleanup>`_

**Required for Gerrit connected systems**

- `Gerrit Trigger <https://plugins.jenkins.io/gerrit-trigger>`_

**Required for GitHub connected systems**

- `GitHub plugin <https://plugins.jenkins.io/github>`_
- `GitHub Pull Request Builder <https://plugins.jenkins.io/ghprb>`_

**Optional**

- `Mask Passwords <https://plugins.jenkins.io/mask-passwords>`_
- `MsgInject <https://plugins.jenkins.io/msginject>`_
- `OpenStack Cloud <https://plugins.jenkins.io/openstack-cloud>`_
- `Timestamps <https://plugins.jenkins.io/timestamper>`_


Environment Variables
---------------------

These variables can be managed by the :ref:`lf-global-jjb-jenkins-cfg-merge`
job however must first be bootstrapped so that the job can take over.

#. Navigate to https://jenkins.example.org/configure

Configure the the environment variables as described in
:ref:`jenkins-cfg-envvar`. Once that's


ci-management
=============

ci-management is a git repository containing :term:`JJB` configuration files
for Jenkins Jobs.
