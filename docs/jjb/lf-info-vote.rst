.. _lf-global-jjb-info-vote:

#############
Info Vote Job
#############

Job counts the votes from the committers against a change
to the INFO.yaml file

If needed, will also check for a majority of TSC voters
(not yet implemented)

Auto-merges the change on a majority vote.


info-vote
---------

:Comment Trigger: recheck|reverify|Vote

:Required parameters:

    :build-node: The node to run build on.
    :jenkins-ssh-credential: Credential to use for SSH. (Generally set
        in defaults.yaml)
