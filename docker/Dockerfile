# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2017 The Linux Foundation
#
# Use the pre-built sigul image published by lfit/releng-sigul-docker
# (Docker Hub: lfreleng/sigul). Building sigul from the Fedora koji RPM at
# release time fails on hosts whose IPs Fedora infra blocks (HTTP 403) — e.g.
# CI datacenters where release-merge jobs run. Pulling a pre-built image
# removes that dependency: the base image already contains sigul and git.
#
# Pin to the published image by digest; bump when a new sigul image is
# released (tag kept in the comment for readability).
FROM lfreleng/sigul:0.2.1@sha256:52773d955ce179b5091b2fb495d95fa584e39380083d7c8449b111627fd02753
SHELL ["/bin/bash", "-c"]

ARG SIGN_DIR="${WORKSPACE}/m2repo"

# fail-fast: ensure the base image actually provides a working sigul
RUN sigul --version

RUN mkdir -p /w/workspace && mkdir -p /home/jenkins

COPY ./sigul-sign.sh /
COPY ./sigul-sign-git-tag.sh /
USER root

ENTRYPOINT ["/bin/bash", "/sigul-sign.sh"]
CMD ["${SIGN_DIR}"]
