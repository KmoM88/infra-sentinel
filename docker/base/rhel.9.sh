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