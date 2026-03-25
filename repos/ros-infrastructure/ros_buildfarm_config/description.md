
# Technical Analysis of ros-infrastructure/ros_buildfarm_config

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** The primary branch is `master`.
- **Branching Strategy:** This repository employs a clear environment-based branching strategy:
  - `master`: This branch is used for the **testing** buildfarm. It's the recommended branch for forks and for testing structural changes.
  - `production`: This branch contains the configuration for the live, public ROS buildfarm at `build.ros.org`. Pull requests for configuration changes (e.g., blacklisting a package) are made against this branch.
  This strategy separates the development and testing of buildfarm configurations from the live production environment.

## 2. Core Purpose & Architecture

- **Core Purpose:** This repository's sole purpose is to provide the configuration for the `ros_buildfarm`. It does not contain any application code itself, but rather a collection of YAML files that define what to build, how to build it, and where to report the results. It is the declarative database that drives the ROS CI/CD process.
- **Architecture:** The architecture is a hierarchical set of YAML files.
  - `index.yaml`: This is the root configuration file. It acts as an index, pointing to other configuration files for different ROS distributions.
  - **Distribution-specific files:** Directories named after ROS distributions (e.g., `kinetic`, `indigo`) contain YAML files that specify the details for different build types (release builds, source builds, documentation builds) and platforms (e.g., `armhf`).
  - This structure allows the `ros_buildfarm` tools to dynamically generate the necessary build jobs based on the selected ROS distribution and build type.

## 3. Consumption (Inputs)

- This repository does not consume any external libraries or frameworks in the traditional sense, as it contains no executable code that has dependencies.
- **Consumed by:** Its configuration is consumed by the tools in the `ros-infrastructure/ros_buildfarm` repository.
- **Referenced Repositories:** The configuration files within this repository reference the `rosdistro` repository (to know which packages are in a distribution) and the actual source code repositories for all the ROS packages it builds.

## 4. Production (Outputs)

- **Configuration:** The "product" of this repository is the configuration itself. These YAML files are not compiled or built. They are read directly by the `ros_buildfarm` scripts.
- It does not produce any packages, binaries, or applications.

## 5. CI/CD Pipeline Analysis

- **No CI/CD:** This repository does not have its own CI/CD pipeline (no `.github/workflows` or `Jenkinsfile` was found). This is expected, as it is a pure configuration repository.
- **CI/CD Consumer:** The validation and testing of this configuration are performed by the CI/CD pipeline of its consumer, the `ros_buildfarm` repository, which has jobs specifically for validating buildfarm configurations.

## 6. Standalone Usage Guide

This repository is not a standalone tool and has no "run" commands. The `README.md` provides a "contributing guide" rather than a quick start.

1.  **Forking:** Fork from the `master` branch for development or testing a private buildfarm.

2.  **Editing Configuration:** Modify the relevant `.yaml` files. For example, to blacklist a package, edit the appropriate `release-build.yaml` file for the target distribution and platform.

3.  **Submitting a Pull Request:**
    - For changes to the testing farm or structural changes, submit a pull request to the `master` branch.
    - For configuration changes intended for the public `build.ros.org`, submit a pull request to the `production` branch.

    Example of blacklisting a package in `kinetic/release-armhf.build`:
    ```yaml
    package_blacklist:
      - my_blacklisted_package
    ```
