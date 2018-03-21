.. _lfreleng-global-jjb:

Linux Foundation Releng Global JJB
==================================

Linux Foundation Release Engineering Global Jenkins Job Builder (JJB)
Documentation.

Global-JJB is a library project containing reusable Jenkins Job Builder
templates. Mainly used by LFCI to deploy management Jenkins jobs to an LF
managed Jenkins instance, there are other jobs defined for which may be helpful
to projects whom use the same build technology. The intention is to save time
for projects from having to define their own job templates.

Release Notes
-------------

Global JJB provides regular releases. The release notes for all releases are
available in the relnotes directory in Git.

https://github.com/lfit/releng-global-jjb/tree/master/relnotes

Guides
------

.. toctree::
   :maxdepth: 2

   best-practices
   configuration

Global JJB Templates
--------------------

Job template code is in the `jjb/` directory but documentation is in the
`docs/jjb/` directory of this project.

- :doc:`jjb/lf-ci-jobs`
- :doc:`jjb/lf-macros`
- :doc:`jjb/lf-maven-jobs`
- :doc:`jjb/lf-node-jobs`
- :doc:`jjb/lf-python-jobs`
- :doc:`jjb/lf-rtd-jobs`

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
