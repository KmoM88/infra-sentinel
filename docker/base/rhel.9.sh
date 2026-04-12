!#/bin/bash

set -e

dnf install -y \
  cmake \
  gcc-c++ \
  git \
  make \
  patch \
  python3-colcon-common-extensions \
  python3-flake8-blind-except \
  python3-flake8-class-newline \
  python3-flake8-deprecated \
  python3-mypy \
  python3-pip \
  python3-pydocstyle \
  python3-pytest \
  python3-pytest-repeat \
  python3-pytest-rerunfailures \
  python3-rosdep \
  python3-setuptools \
  python3-vcstool \
  wget

dnf update -y && dnf upgrade -y
dnf install -y 'dnf-command(config-manager)' epel-release
dnf config-manager --set-enabled ubi-9-codeready-builder-rpms
dnf config-manager --set-enabled ubi-9-appstream-rpms
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/x86_64/os/
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf clean all
dnf makecache
rpm -e --nodeps openssl-fips-provider-so || true
dnf update -y --allowerasing