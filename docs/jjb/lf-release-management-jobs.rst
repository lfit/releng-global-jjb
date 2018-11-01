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
    :jenkins-ssh-credential: Credential to use for SSH. (Configured in
        defaults.yaml)
