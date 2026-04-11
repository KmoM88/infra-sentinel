#!/bin/bash

set -e

ROS2_VERSION="kilted"

apt-get update && apt-get install -y \
    python3-flake8-blind-except \
    python3-flake8-builtins \
    python3-flake8-class-newline \
    python3-flake8-comprehensions \
    python3-flake8-deprecated \
    python3-flake8-import-order \
    python3-flake8-quotes \
    python3-pytest-repeat \
    python3-pytest-rerunfailures \
    python3-flake8-docstrings \
    python3-pip \
    python3-pytest-cov \
    ros-dev-tools

mkdir -p ~/ros_${ROS2_VERSION}/src
cd ~/ros_${ROS2_VERSION}
vcs import --input https://raw.githubusercontent.com/ros2/ros2/${ROS2_VERSION}/ros2.repos src

apt-get upgrade -y

cd ~/ros_${ROS2_VERSION}
rosdep init
rosdep update
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

cd ~/ros_${ROS2_VERSION}
colcon build --symlink-install

echo "source ~/ros_${ROS2_VERSION}/install/setup.bash" >> ~/.bashrc
