# SPDX-License-Identifier: EPL-1.0
# SPDX-FileCopyrightText: 2017 The Linux Foundation
FROM centos:7
SHELL ["/bin/bash", "-c"]

ARG SIGN_DIR="${WORKSPACE}/m2repo"

RUN echo $'[fedora-infra-sigul] \n\
name=Fedora builder packages for sigul \n\
baseurl=https://kojipkgs.fedoraproject.org/repos-dist/epel\$releasever-infra/latest/\$basearch/ \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://infrastructure.fedoraproject.org/repo/infra/RPM-GPG-KEY-INFRA-TAGS \n\
includepkgs=sigul* \n\
skip_if_unavailable=True' > /etc/yum.repos.d/fedora-infra-sigul.repo

RUN sed -i_ 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* || exit 1
RUN sed -i_ 's@#baseurl=http://mirror.centos.org@baseurl=http://vault.centos.org@g' /etc/yum.repos.d/CentOS-* || exit 1

# install git (needed for sign-git-tag to modify tag objects)
RUN yum install -y git && yum clean all

# install sigul separately to ensure failures are not masked by git's success
# NOTE: combining with git in a single yum install causes silent failures
# when the RPM URL is unreachable — yum returns 0 if git installs successfully
RUN yum install -y \
    https://kojipkgs.fedoraproject.org//packages/sigul/0.207/1.el7/x86_64/sigul-0.207-1.el7.x86_64.rpm \
    && yum clean all

# fail-fast: verify sigul is actually installed and functional
RUN sigul --version

RUN mkdir -p /w/workspace && mkdir -p /home/jenkins

COPY ./sigul-sign.sh /
COPY ./sigul-sign-git-tag.sh /
USER root

ENTRYPOINT ["/bin/bash", "/sigul-sign.sh"]
CMD ["${SIGN_DIR}"]
