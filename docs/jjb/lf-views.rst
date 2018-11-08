.. _lf-global-jjb-views:

#############
Jenkins Views
#############

View Templates
==============

JJB view-templates provides a way to manage Jenkins views through code. Using
view-templates we can define common views configuration that are interesting
to a project.

We recommend creating separate project sections for views apart from job
configuration such that job configuration does not overlap with the view
configuration.

Example Usage:

.. code-block:: yaml

   ---
   - project:
       name: project-view
       views:
         - common-view

       project-name: project

   - project:
       name: project-stream1
       jobs:
         - '{project-name}-{seq}'

       project: project
       project-name: project
       seq:
         - a
         - b

   - project:
       name: project-stream2
       jobs:
         - '{project-name}-{seq}'

       project: project
       project-name: project
       seq:
         - x
         - y

   - job-template:
       name: '{project-name}-{seq}'


Project view
------------

Groups all jobs owned by a project under one view by capturing jobs with the
prefix of ``project-name``.

This view uses the following columns:

:Columns:

    - status
    - weather
    - job
    - last-success
    - last-failure
    - last-duration
    - build-button
    - jacoco
    - find-bugs

:Template Names:

    - {project-name}
    - project-view

:Required parameters:

    :project-name: The name of the project utilizing the view.

:Optional parameters:

    :view-filter-executors: View filter executor. (default: false)
    :view-filter-queue: View filter queue. (default: false)
    :view-recurse: View recurse. (default: false)

Example:

.. literalinclude:: ../../.jjb-test/lf-project-view.yaml
   :language: yaml


Common view
-----------

Groups all jobs owned by a project under one view by capturing jobs with the
prefix of ``project-name``.

This view uses the following columns:

:Columns:

   - status
   - weather
   - job
   - last-success
   - last-failure
   - last-duration
   - build-button
   - jacoco
   - find-bugs

:Template Names:

   - {view-name}
   - common-view

:Required parameters:

   :view-name: The name of the view.
   :view-regex: Regex to match the jobs.

:Optional parameters:

   :view-filter-executors: View filter executor. (default: false)
   :view-filter-queue: View filter queue. (default: false)
   :view-recurse: View recurse. (default: false)

Example:

.. literalinclude:: ../../.jjb-test/lf-common-view.yaml
  :language: yaml


CSIT view template
------------------

View template that loads columns useful for CSIT jobs.

This view uses the following columns:

:Columns:

    - status
    - weather
    - job
    - last-success
    - last-failure
    - last-duration
    - build-button
    - robot-list

:Template Names:

    - {view-name}
    - csit-view

:Required parameters:

    :view-name: The name of the view.
    :view-regex: Regex to match the jobs.

:Optional parameters:

    :view-description: View description. (default: 'CSIT Jobs.')
    :view-filter-executors: View filter executor. (default: false)
    :view-filter-queue: View filter queue. (default: false)
    :view-recurse: View recurse. (default: false)

Example:

.. literalinclude:: ../../.jjb-test/lf-csit-view.yaml
   :language: yaml
