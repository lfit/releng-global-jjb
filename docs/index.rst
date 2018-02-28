.. _lfreleng-global-jjb:

Linux Foundation Releng Global JJB
==================================

Linux Foundation Release Engineering Global Jenkins Job Builder (JJB)
Documentation.

Global-JJB is a library project containing reusable Jenkins Job Builder
templates that can be deployed to any project. It is mainly used by LFCI to
deploy management Jenkins jobs to an LF managed Jenkins instance however there
are other jobs defined for various software languages which may be helpful
to projects whom use the same build technology. It is intended to save time
for projects from having to define their own job templates.

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
