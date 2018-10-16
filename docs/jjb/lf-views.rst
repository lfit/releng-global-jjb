.. _lf-global-jjb-views:

#############
Jenkins Views
#############

View Templates
==============

JJB view-templates provides a way to manage Jenkins views through code.


Common view
-----------

Common view groups jobs related to a project and supports the following
columns.

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
    - robot-list

:Template Names:
    - common-view
    - {project-name}

:Required parameters:

    :project-name: The name of the view.

:Optional parameters:

    :view-description: View description. (Generally set in defaults.yaml)
    :view-regex: Regex to match the jobs. (Generally set in defaults.yaml)
    :view-filter-executors: View filter executor. (Generally set in defaults.yaml)
    :view-filter-queue: View filter queue. (Generally set in defaults.yaml)
    :view-recurse: View recurse. (Generally set in defaults.yaml)


Integration CSIT view
---------------------

Integration CSIT view provides a view for integration or CSIT jobs.
The view supports the following set of columns.

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
    - integration-csit-view
    - {project-name}

:Required parameters:

    :project-name: The name of the view.

:Optional parameters:

    :view-description: View description. (Generally set in defaults.yaml)
    :view-regex: Regex to match the jobs. (Generally set in defaults.yaml)
    :view-filter-executors: View filter executor. (Generally set in defaults.yaml)
    :view-filter-queue: View filter queue. (Generally set in defaults.yaml)
    :view-recurse: View recurse. (Generally set in defaults.yaml)
