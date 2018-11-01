#!/bin/bash
set -eux -o pipefail

mail_opts=()
mail_opts+=("-r" "Jenkins <dontreply@jenkins.opendaylight.org>")
mail_opts+=("-s" "$PROJECT $GERRIT_REFSPEC released")
mail_opts+=("Thanh Ha <thanh.ha@linuxfoundation.org>")

mail_body="Hi Everyone,

$PROJECT $GERRIT_REFSPEC is released. Thanks to everyone who contributed
to this release. Release notes are available online at:

https://docs.releng.linuxfoundation.org/projects/$PROJECT/en/latest/release-notes.html#v0-XX-0

Cheers,
LF Releng
"
eval echo "" | mail "${mail_opts[@]}"
