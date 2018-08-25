Job groups are a great tool to configure multiple jobs together at the same
time. Below are some starting point job-groups which can be used however we
recommend creating your own to ensure that the jobs configured reflect your
project.

An example project:

.. code-block:: yaml

    - job-group:
        name: odl-maven-jobs

        jobs:
          - gerrit-maven-clm
          - gerrit-maven-merge
          - gerrit-maven-release
          - gerrit-maven-verify
          - gerrit-maven-verify-dependencies:
              build-timeout: 180

        mvn-version: mvn35

    - project:
        name: aaa
        jobs:
          - odl-maven-jobs

In this example we are using the job-group to assign a list of common jobs to
the aaa project. The job-group also hardcodes ``mvn-version`` to *mvn35* and
``build-timeout`` to *180* for all projects using this job-group.

A benefit of this method is for example disabling entire category of jobs by
only modifying the job-group by inserting ``disable-jobs: true`` parameter
against the jobs that need to be disabled.
