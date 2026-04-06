# `ament/ament_cmake` Technical Analysis

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `rolling`. The repository follows a branching strategy aligned with ROS (Robot Operating System) distributions. Each major branch (e.g., `foxy`, `galactic`, `humble`, `iron`, `jazzy`) corresponds to a specific ROS release. The `rolling` branch serves as the main development branch for the upcoming ROS 2 release, accumulating new features and changes before they are backported to other active distributions. A `master` branch also exists but `rolling` is the default.

## 2. Core Purpose & Architecture

This repository, `ament_cmake`, provides the core CMake infrastructure for the `ament` build system, which is the standard build system for ROS 2. It is not a single application but a collection of CMake macros, functions, and scripts that enable the building, testing, and installation of ROS 2 C++ and Python packages.

The architecture is highly modular, consisting of multiple sub-packages within this single repository (a "meta-package"). Each sub-package provides a specific piece of functionality:

-   `ament_cmake_core`: The fundamental macros for package handling.
-   `ament_cmake_python`: Support for Python packages.
-   `ament_cmake_gtest` / `ament_cmake_gmock`: Integration with Google Test and Google Mock for C++ testing.
-   `ament_cmake_pytest`: Integration with `pytest` for Python testing.
-   And many others for linting, code checking, and exporting package information.

This modular design allows ROS packages to declare fine-grained dependencies on the specific build features they need.

## 3. Consumption (Inputs)

`ament_cmake` and its sub-packages consume the following:

-   **Build Tools**:
    -   `cmake`: The fundamental build tool.
-   **Core ROS/ament Packages**:
    -   `ament_package`: A Python package for parsing `package.xml` files.
    -   `python3-catkin-pkg-modules`: A Python package for reading `package.xml` files.
-   **Testing Frameworks**:
    -   `gtest` / `gmock`: For C++ unit testing.
    -   `pytest`: For Python unit testing.
-   **VCS Tools**:
    -   `git`: Used by some macros for vendoring packages.
    -   `python3-vcstool`: Used for vendoring external repositories.

Dependencies are declared in the `package.xml` file within each sub-package directory.

## 4. Production (Outputs)

This repository does not produce a standalone binary, library, or application. Its primary output is the **CMake build infrastructure** itself.

When a ROS 2 workspace is built, the CMake files from `ament_cmake` are installed into the workspace's `install` directory. This makes the macros and functions available to other ROS 2 packages in the workspace, which find and use them via `find_package(ament_cmake)`.

## 5. CI/CD Pipeline Analysis

No CI/CD pipeline configurations (e.g., `.github/workflows/` or `Jenkinsfile`) were found directly within this repository.

Given the nature of the project as a core component of the ROS 2 ecosystem, it is highly likely that CI is handled by a centralized system that builds and tests many repositories together. The CI for ROS 2 is managed through a combination of `build.ros2.org` and dedicated CI repositories, which are not part of `ament_cmake` itself.

## 6. Standalone Usage Guide

As a core part of the ROS 2 build system, `ament_cmake` is not typically used "standalone." It is used as a dependency when building a ROS 2 workspace with `colcon`, the standard ROS 2 build tool.

A developer would typically follow these steps to use/build this repository as part of a larger workspace:

1.  **Create a ROS 2 Workspace:**
    ```bash
    mkdir -p ~/ros2_ws/src
    cd ~/ros2_ws
    ```

2.  **Clone the Repository:**
    ```bash
    git clone https://github.com/ament/ament_cmake.git src/ament_cmake
    ```

3.  **Install Dependencies:**
    Use `rosdep` to install system dependencies for all packages in the workspace.
    ```bash
    rosdep install --from-paths src --ignore-src -r -y
    ```

4.  **Build the Workspace:**
    Use `colcon` to build the packages. `colcon` will automatically use the `ament_cmake` packages to build themselves and any other packages in the workspace that depend on them.
    ```bash
    colcon build --symlink-install
    ```
