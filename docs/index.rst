.. _lfreleng-global-jjb:

Linux Foundation Releng Global JJB
==================================

Linux Foundation Release Engineering Global Jenkins Job Builder (JJB)
Documentation.

Global-JJB is a library project containing reusable Jenkins Job Builder
templates. Developed for LFCI to deploy management Jenkins jobs to an LF
managed Jenkins instance, there are other jobs defined which may be helpful
to projects that use the same build technology. The intention is to help
projects save time from having to define their own job templates.

Release Notes
-------------

Global JJB provides regular releases. The release notes for all releases are
available in the relnotes directory in Git.

https://github.com/lfit/releng-global-jjb/tree/master/relnotes

Guides
------

.. toctree::
   :maxdepth: 2

   release-notes
   install
   configuration

   best-practices
   glossary
   appendix

Global JJB Templates
--------------------

Job template code is in the `jjb/` directory but documentation is in the
`docs/jjb/` directory of this project.

.. toctree::
   :glob:
   :maxdepth: 1

   jjb/*

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
