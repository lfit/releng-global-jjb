.. _global-jjb-best-practices:

##############
Best Practices
##############

JJB YAML Layout
===============

.. note::

    While some of this applies to the Global JJB project other recommendations
    are generally useful to projects that might be defining JJB templates.

The Global JJB project is a useful example project to look at so we recommend
referring to the Maven job definitions as an example as you read the
documentation below:

https://github.com/lfit/releng-global-jjb/blob/master/jjb/lf-maven-jobs.yaml

We recommend sectioning off the template into 3 general sections in order:

1. Job Groups (optional)
2. Common Functions
3. Job Template Definitions

In section 1) not all configurations need this so is an optional section. Job
groups are useful in cases where there are jobs that are generally useful
together. For example the OpenDaylight uses a lot of Merge and Verify job
combinations so every new project will want both job types defined in their
project.

In section 2) we want to define all common functions (anchors, aliases, macros)
that are generally useful to all jobs in the file. This allows job template
developers to look at the top of the file to see if there are useful functions
already defined that they can reuse.

In section 3) we can declare our job definitions. In the Global JJB project we
create Gerrit and GitHub versions of the jobs so the format we use here
might look strange at first but is well layed out for code reuse if we need to
define 2 or more versions of the same job template for different systems. We
will define this in more detail in the next section.

Job Template Layout
-------------------

1. Comment of Job Template Name
2. Macro containing build definition of the job
   a. Macro named after job
   b. Complete documentation of the job parameters
   c. Default parameters defined by the job
   d. Job configuration
3. job-template definition containing build triggers

In section 1) we need to declare a in large comment text to identify the job
section.

In section 2) we declare the actual job definition. This is so that we have a
single macro that we call in all the real job-template sections that is
reusable and not duplicating any code. First we declare the macro as the job
name. Then in 2.b) we provide the complete documentation of the job parameters
this is so that we can link users of the job to this file and they can
understand fully what options they can configure for this particular job.
Then we define defaults for any parameters that are optional. The last section
we define the job configuration which completes the macro.

In section 3) we declare the actual job-template. Because of all the
preparations above job template definitions should be small and simple. It
needs to define the scm and job triggers. The Global JJB project needs to
support both Gerrit and GitHub versions of the same job so the job definitions
there have 2 templates for each job defined.


Passing parameters to shell scripts
===================================

There are 2 ways to pass parameters into scripts:

1. JJB variables in the format {var}
2. Environment variables in the format ${VAR}

We recommend avoiding using method 1 (Pass JJB variables) into shell scripts
and instead always use method 2 (Environment variables). This makes
troubleshooting JJB errors easier and does not require escaping curly braces.

This method requires 3 steps:

1. Declare a parameter section or inject the variable as properties-content.
2. Invoke the shell script with `include-raw-escape` instead of `include-raw`.
3. Use the shell variable in shell script.


The benefit of this method is that parameters will always be at the top
of the job page and when clicking the Build with Parameters button in Jenkins
we can see the parameters before running the job. We can review the
parameters retro-actively by visiting the job parameters page
``job/lastSuccessfulBuild/parameters/``. Injecting variables as
properties-content makes the variable local to the specific macro, while
declaring it as parameter makes the variable global.

.. note::

    When a macro which invokes a shell script has no JJB parameters defined
    `!include-raw-escape` will insert extra curly braces, in such cases its
    recommended to use `!include-raw`.

.. _shell-scripts:

Shell scripts
=============

When developing shell scripts for JJB we recommend to create shell scripts as
a separate file instead of inlining in YAML. This way we can ensure that the
ShellCheck linter can catch potential issues with the scripts.

When writing the script itself, we recommend to redeclare all expected
inputs at the top of the file using lowercase variable names before setting
``set -u`` after the inputs section. This ensures that all variables the
script expects are at the top of the file which is useful for others to review
and debug the script at a later stage. The ``set -u`` configuration before the
start of the script code ensures that we catch any of these undeclared
variables at the top of the file.

Example:

.. code-block:: bash

   #!/bin/bash

   # Inputs
   tox_dir="${TOX_DIR:-$WORKSPACE}"
   tox_envs="${TOX_ENVS:-}"

   # Script start
   set -eux -o pipefail

   # ... script code goes here

Usage of config-file-provider
=============================

When using the config-file-provider plugin in Jenkins to provide a config file.
We recommend using a macro so that we can configure the builder to
remove the config file as a last step. This ensures
that credentials do not exist on the system for longer than it needs to.

ship-logs example:

.. code-block:: yaml

    - builder:
        name: lf-ship-logs
        builders:
          - config-file-provider:
              files:
                - file-id: jenkins-log-archives-settings
                  variable: SETTINGS_FILE
          - shell: !include-raw:
              - ../shell/logs-get-credentials.sh
          - shell: !include-raw:
              - ../shell/lftools-install.sh
              - ../shell/logs-deploy.sh
          - shell: !include-raw:
              - ../shell/logs-clear-credentials.sh
          - description-setter:
              regexp: '^Build logs: .*'

In this example the script logs-deploy requires a config file to authenticate
with Nexus to push logs up. We declare a macro here so that we can ensure that
we remove credentials from the system after the scripts
complete running via the logs-clear-credentials.sh script. This script contains
3 basic steps:

1. Provide credentials via config-file-provider
2. Run the build scripts in this case lftools-install.sh and logs-deploy.sh
3. Remove credentials provided by config-file-provider

.. _preserve-variable-refs:

Preserving Objects in Variable References
=========================================

JJB has an option to preserve a data structure object when you want to pass
it to a template.
https://docs.openstack.org/infra/jenkins-job-builder/definition.html#variable-references

One thing that is not explicitly covered is the format of the variable name
that you pass the object to. When you use the `{obj:key}` notation to preserve
the original data structure object, it will not work if the variable name has a
dash `-` in it. The standard that we follow, and recommend, is to use an underscore
`_` instead of a dash.

Example:

.. code-block:: yaml

   .. literalinclude:: _static/github-pr-trigger.example

In the above example note the use of underscores in ``github_pr_whitelist``,
``github_pr_admin_list``, and ``github_included_regions``.

Using single quotes around variables
====================================

Its recommended to use single quotes around JJB variables '{variable}-field'
during variable substitution or when using a variable in a string field, in
other cases its recommended to drop the single quotes.

Example:

.. code-block:: yaml

    - builder:
        name: lf-user-logs
        builders:
          - inject:
              properties-content: |
                  'HOME={user-home}'
          - build-file:
              settings: '{settings-file}'
              file-version: '{file-version}'


Variable expansion and Defaults
===============================

.. This documentation uses work originally provided by Thanh Ha on
.. the OpenDaylight dev mailing list.
.. https://lists.opendaylight.org/pipermail/dev/2017-October/004184.html

JJB has a concept called :ref:`Defaults <defaults>` which is what JJB will
replace a variable with if unset. Variables can configure dynamic content
in :ref:`job-template <job-template>` sections and allow certain options in
these sections to be configurable.

The section that expands Defaults is :ref:`Job Templates <job-template>` no
other sections will expand a default. This documentation will explain how
variables and defaults expansion works and which take precedence in JJB's
variable expansion logic for the following configuration sections.

- macro
- job-template
- project
- default

Macro sections
--------------

:ref:`Macro <macro>` sections can contain variables but do **NOT** support
default values getting filled in both at the macro definition level and at the
defaults configuration level. :ref:`Macros <macro>` and
:ref:`Job Templates <job-template>` can use Macros but any variables defined in
a Macro needs to pass a value or a new variable redefined in the
:ref:`Job Template <job-template>` if you want to pass on the configuration.

So for example if you have a macro that has a '{msg}' variable:

Example:

.. code-block:: yaml

   - builder:
       name: echo-msg
       builders:
         - shell: "echo {msg}"

Any downstream job-templates or macros that use this macro **MUST** pass in a
`msg: Hello` definition or redefine the msg variable `msg: {msg}`.


Job Template sections
---------------------

:ref:`Job Template <job-template>` sections can use defaults in two ways.

1. Configure the message:

   .. code-block:: yaml

      - job-template:
          name: echo-hello-world
          builders:
            - echo-msg:
                msg: 'Hello World'

2) Re-define '{msg}' variable

   .. code-block:: yaml

      - job-template:
          name: echo-message
          builders:
            - echo-msg:
                msg: '{message}'

In option 2, we redefine the variable msg as `{message}` which a user of the
job-template can now pass into the job their own custom message which is
different than option 1, where we set a static message to pass in. We purposely
redefined the **{msg}** to **{message}** here to show that you do not need to
redefine it with the same name but we could have used the same name `{msg}` in
the template too if we wanted to keep it the same.

Job Templates can also default a default variable for the variables it defines.

Example:

.. code-block:: yaml

    - job-template:
      name: echo-message
      message: 'Hello World'
      builders:
        - echo-msg:
            msg: '{message}'

This creates a job template variable called '{message}' which will default to
"Hello World" if the user of the template does not explicitly pass in a message.

We should be aware of 2 Defaults concepts:

1. Default as defined in the :ref:`job-template <job-template>`
2. Default as defined in a :ref:`defaults <defaults>` configuration
   (typically defaults.yaml)

In this case there is a default '{message}' set in the
:ref:`job-template <job-template>`. JJB will use this default if the user
(project section) does not declare a {message}.

If we do not declare a default in the :ref:`job-template <job-template>` then
JJB will fallback to checking the "defaults configuration".

This means that the precendence of defaults is as follows:

1. User-provided
2. Job Template
3. Defaults.yaml

Project sections
----------------

:ref:`Project <project>` sections define real jobs and pass in variables as
necessary. Projects sections do NOT expand defaults.yaml. So you cannot
configure a setting with {var} in here and expect defaults.yaml to fill it in
for you. Define required configuration here.

Example:

.. code-block:: yaml

   - project
       name: foo
       jobs:
         - 'echo-message'
       message: 'I am foo'


Defaults sections
-----------------

:ref:`Defaults <defaults>` sections are the absolute last thing JJB checks if a
variable is not configured in a job-template and user did not pass in the
variable. JJB will fill in whatever is in the defaults configuration.

Variable expansion order of precedence seems to be:

1. job-group section definition
2. project section definition
3. job-template variable definition
4. defaults.yaml variable definition

.. note:: Defaults set variables in job-templates and are NOT used in Macros.

global-jjb should not provide job-group definitions and leave it up to users of
global-jjb to create their own as a job-group as a variable defined in a job
group the highest precendence. Global JJB should strive to be purely a
job-template and macro library for downstream consumers.

Final thoughts
--------------

For any :ref:`Basic Job Configuration <job>` for example "concurrent", "jdk",
"node" etc... we cannot set defaults with the same name as JJB will not expand
them. To use "node" we need to give the variable for that setting a
different name such as "build-node" instead, if we want JJB to perform
expansion for those settings. This issue affects top level job configuration,
it does not appear to affect items below the top level such as calling a
builder, wrapper or parameter.
