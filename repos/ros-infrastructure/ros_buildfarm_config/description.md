# ros-infrastructure/ros_buildfarm_config Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository employs a dual-branch strategy:
    - `master`: This branch is used for the testing farm and for proposing and testing structural changes to the configuration.
    - `production`: This branch contains the configuration for the live ROS buildfarm at `build.ros.org`. Pull requests for configuration changes (e.g., blacklisting a package) should be made against this branch.

## 2. Core Purpose & Architecture

This repository contains the configuration for the ROS buildfarm. It does not contain any application code, but rather a set of YAML files that define the build parameters for various ROS distributions. The architecture is purely data-driven, with the `ros_buildfarm` tool consuming these files to generate Jenkins jobs.

The configuration is organized hierarchically, with an `index.yaml` file at the root that points to more specific configuration files for each ROS distribution.

## 3. Consumption (Inputs)

- **Consumers:** This repository is consumed by the `ros_buildfarm` tool.
- **Dependencies:** There are no external library dependencies, as this is a configuration repository.

## 4. Production (Outputs)

This repository does not produce any packages or binaries. Its "output" is the configuration data itself, which is consumed by the `ros_buildfarm`.

## 5. CI/CD Pipeline Analysis

There is no CI/CD pipeline configured in this repository (i.e., no `.github/workflows` or `Jenkinsfile`). The validation of this configuration is likely performed by the CI/CD pipeline of the `ros_buildfarm` repository or other external tooling.

## 6. Standalone Usage Guide

This repository is not meant to be used standalone. It is a configuration repository for the `ros_buildfarm`. To contribute changes, you should fork the repository, create a new branch from either `master` or `production` (depending on the nature of the change), and then submit a pull request.

The `README.md` provides specific instructions for blacklisting packages, which is a common type of contribution.

## 7. Execution Flow Walkthrough

The execution flow described here is from the perspective of the `ros_buildfarm` tool consuming this configuration.

1.  **Entry Point (`index.yaml`):** The `ros_buildfarm` tool starts by parsing the `index.yaml` file at the root of the repository. This file serves as the main entry point to the configuration and contains:
    - A `distributions` dictionary that maps ROS distribution names (e.g., `kinetic`) to their respective configuration files.
    - The URL of the Jenkins server (`jenkins_url`).
    - Default notification email addresses.
    - Prerequisite Debian repositories and GPG keys.
    - The URL of the `rosdistro` index file.

2.  **Distribution-Specific Configuration:** For a given ROS distribution (e.g., `kinetic`), `ros_buildfarm` looks up the corresponding entry in the `distributions` dictionary in `index.yaml`. This entry contains paths to other YAML files for different build types:
    - `doc_builds`: Configuration for generating documentation.
    - `release_builds`: Configuration for building binary packages (e.g., `.deb` files).
    - `source_builds`: Configuration for building from source.

3.  **Build File Parsing (e.g., `kinetic/release-build.yaml`):** `ros_buildfarm` then parses the appropriate build file for the desired build type. For example, a release build for Kinetic would use `kinetic/release-build.yaml`. These files contain detailed parameters for the build, such as:
    - `jenkins_binary_job_priority` and `jenkins_binary_job_timeout`: Jenkins job parameters.
    - `notifications`: Email notification settings.
    - `package_blacklist`: A list of packages to exclude from the build.
    - `sync`: Parameters for syncing with the main repositories.
    - `repositories`: The Debian repositories to use for the build.
    - `targets`: The specific architectures and operating systems to build for (e.g., `ubuntu: xenial: amd64`).

4.  **Job Generation:** Using the parsed information from this chain of configuration files, `ros_buildfarm` generates the necessary Jenkins jobs or local build scripts.
