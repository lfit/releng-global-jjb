---
Job Templates
=============

.. _release-announce:

Release Announce
----------------

Job for lf-releng projects to automate release announcement emails.

:Template Names:
    - {project-name}-release-announce
    - gerrit-release-announce

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally
        should be configured in defaults.yaml)
