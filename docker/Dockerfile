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
FROM lfreleng/sigul:0.1.0@sha256:e8b958a6e5ba3ee6334c0244e9fbe0881248133e97bc77236a176baa5d219cbd
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
