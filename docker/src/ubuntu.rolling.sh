#!/bin/bash

set -e

apt-get update && apt-get install -y \
    python3-mypy \
    python3-pip \
    python3-pytest \
    python3-pytest-cov \
    python3-pytest-mock \
    python3-pytest-repeat \
    python3-pytest-rerunfailures \
    python3-pytest-runner \
    python3-pytest-timeout \
    python3-pyqt6 \
    pyqt6-dev \
    python3-pyqt6.sip \
    python3-sip-dev \
    qt6-base-dev \
    qt6-core-dev \
    qt6-gui-dev \
    ros-dev-tools

mkdir -p ~/ros_${ROS2_VERSION}/src
cd ~/ros_${ROS2_VERSION}
vcs import --input https://raw.githubusercontent.com/ros2/ros2/${ROS2_VERSION}/ros2.repos src

apt-get upgrade -y

cd ~/ros_${ROS2_VERSION}
rosdep init
rosdep update
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-7.7.0 urdfdom_headers"

cd ~/ros_${ROS2_VERSION}
colcon build --symlink-install

echo "source ~/ros_${ROS2_VERSION}/install/setup.bash" >> ~/.bashrc
