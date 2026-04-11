# ros2/ros_buildfarm_config Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `ros2`
- **Branching Strategy:** The repository uses a dual-branch strategy for development and production:
    - `master`: This branch is used for the testing farm and for proposing and testing structural changes to the configuration.
    - `ros2`: This is the production branch, containing the configuration for the live ROS 2 buildfarm at `build.ros2.org`.

## 2. Core Purpose & Architecture

This repository contains the configuration for the ROS 2 buildfarm. It is a data-driven repository, consisting almost entirely of YAML files that define the build parameters for various ROS 2 distributions. The `ros_buildfarm` tool consumes these files to generate Jenkins jobs.

The configuration is organized hierarchically. An `index.yaml` file at the root serves as the entry point, linking to more specific configuration files organized by ROS 2 distribution (e.g., `humble`, `jazzy`, `rolling`).

## 3. Consumption (Inputs)

- **Consumers:** This repository is consumed by the `ros_buildfarm` tool.
- **Dependencies:** The repository has no external library dependencies. It does, however, have a CI dependency on `ros-infrastructure/ros_buildfarm` for validation scripts.

## 4. Production (Outputs)

This repository does not produce any packages or binaries. Its sole "output" is the configuration data within the YAML files, which is used to drive the ROS 2 buildfarm.

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for CI/CD, with the workflow defined in `.github/workflows/ci.yaml`.

-   **Triggers:** The pipeline is triggered on `push` events to the `master`, `production`, and `ros2` branches, and on `pull_request` events.
-   **Jobs:**
    -   `validate`: This job checks out both this repository and the `ros-infrastructure/ros_buildfarm` repository. It then uses the `validate_config_index.py` script from `ros_buildfarm` to validate the buildfarm configuration, starting from the `index.yaml` file.
    -   `yamllint`: This job ensures that all YAML files in the repository adhere to the defined style guidelines.

## 6. Standalone Usage Guide

This repository is not intended for standalone use. It provides the configuration for an instance of `ros_buildfarm`. To contribute, you should fork the repository, create a branch from `master` or `ros2`, and submit a pull request with your changes.

## 7. Execution Flow Walkthrough

The execution flow described here is from the perspective of the `ros_buildfarm` tool consuming this configuration.

1.  **Entry Point (`index.yaml`):** The process begins when `ros_buildfarm` parses the root `index.yaml` file. This file contains:
    -   A `distributions` dictionary, which maps ROS 2 distribution names (e.g., `humble`) to their specific configuration files.
    -   Global build configurations for CI (`ci_builds`) and documentation (`doc_builds`).
    -   The URL of the Jenkins server (`jenkins_url`).
    -   Default notification email addresses.
    -   Prerequisite Debian repositories and GPG keys.
    -   The URL of the `rosdistro` index file.

2.  **Distribution-Specific Configuration:** For a given ROS 2 distribution (e.g., `humble`), `ros_buildfarm` looks up its entry in the `distributions` dictionary in `index.yaml`. This entry points to other YAML files for different build types:
    -   `ci_builds`: Configuration for various CI jobs (e.g., `nightly-release`, `benchmark`).
    -   `doc_builds`: Configuration for documentation generation jobs.
    -   `release_builds`: Configuration for building binary packages (e.g., `.deb`, `.rpm`).
    -   `source_builds`: Configuration for building from source.

3.  **Build File Parsing (e.g., `humble/release-build.yaml`):** `ros_buildfarm` then parses the appropriate build file. For example, a release build for Humble would use `humble/release-build.yaml`. These files contain detailed build parameters, such as:
    -   `jenkins_binary_job_priority` and `jenkins_binary_job_timeout`: Jenkins job parameters.
    -   `notifications`: Email notification settings.
    -   `package_blacklist`: A list of packages to exclude from the build.
    -   `repositories`: The Debian repositories to use for the build.
    -   `targets`: The specific architectures and operating systems to build for (e.g., `ubuntu: jammy: amd64`).

4.  **Job Generation:** Using the aggregated information from this chain of configuration files, `ros_buildfarm` generates the necessary Jenkins jobs or local build scripts.
