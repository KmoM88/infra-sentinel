# Analysis of `create_jenkins_job.py` in ros2/ci

This document provides a detailed breakdown of the `create_jenkins_job.py` script from the `ros2/ci` repository. Its primary function is to programmatically generate and configure Jenkins jobs for the continuous integration and packaging of ROS 2.

## 1. Script Overview

The script uses the `ros_buildfarm` Python library and `empy` templates to generate Jenkins XML job configurations. It connects to a Jenkins instance, reads template files, injects configuration data, and then creates or updates the corresponding jobs on the server.

The core logic revolves around a set of base configurations which are then specialized for different operating systems and job types (e.g., simple CI, packaging, nightly builds, coverage analysis).

## 2. Execution and Configuration

The script is executed from the command line. Its behavior is controlled by several arguments.

### Command-Line Arguments

| Argument                      | Default Value                  | Description                                                                 |
| ----------------------------- | ------------------------------ | --------------------------------------------------------------------------- |
| `--jenkins-url`, `-u`         | `https://ci.ros2.org`          | The URL of the Jenkins server.                                              |
| `--ci-scripts-repository`     | `git@github.com:ros2/ci.git`   | The repository containing the CI scripts that the Jenkins jobs will execute. |
| `--ci-scripts-default-branch` | `master`                       | The default git branch of the CI scripts repository to use in the jobs.     |
| `--commit`                    | `False` (Dry run)              | When this flag is present, the script will actually modify the Jenkins jobs. Otherwise, it only prints a diff of the changes. |
| `--select-jobs-regexp`        | `''` (empty string)            | A regular expression to filter which jobs are created or updated. If empty, all jobs are processed. |
| `--context-lines`             | `0`                            | The number of context lines to show in the diff when `--commit` is not used. |

## 3. Core Logic & Job Generation

The script follows these steps to generate jobs:

1.  **Initialization**: It connects to the Jenkins instance specified by `--jenkins-url`.
2.  **Base Configuration**: It defines a `data` dictionary that holds default values for Jenkins job parameters. This includes:
    -   `default_repos_url`: `https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos`
    -   `build_args_default`: Default arguments for the colcon build command.
    -   `test_args_default`: Default arguments for the colcon test command.
    -   And many others, like mailer recipients and timeout values.
3.  **OS-Specific Configuration**: An `os_configs` dictionary defines configurations for each target operating system. This is the most critical part for determining where jobs run.
4.  **Job Iteration**: The script iterates through each defined OS (`linux`, `windows`, `windows-2025`, `linux-aarch64`, `linux-rhel`) and creates a suite of Jenkins jobs for it.
5.  **Template Expansion**: For each job, it:
    -   Selects a template file (`ci_job.xml.em` or `packaging_job.xml.em`).
    -   Merges the base `data`, the specific `os_configs`, and job-specific parameters into a single dictionary.
    -   Uses `ros_buildfarm.templates.expand_template` to process the `.em` file and generate the final Jenkins XML configuration.
6.  **Job Creation/Update**: The generated XML is pushed to the Jenkins server using `ros_buildfarm.jenkins.configure_job`.

## 4. Job Templates and Definitions

The job definitions are not hardcoded in Python but are externalized into template files located in the `job_templates/` directory. The script primarily uses three templates.

### Key Template: `ci_job.xml.em`

-   **Purpose**: Defines a standard CI build-and-test job.
-   **Agent Label**: The agent is assigned via `<assignedNode>@(label_expression)</assignedNode>`, which directly uses the `label_expression` from the script's `os_configs`.
-   **Parameters**: It defines a wide range of Jenkins parameters (e.g., `CI_BRANCH_TO_TEST`, `CI_CMAKE_BUILD_TYPE`) which are populated by the script. These allow for manual customization of a build.
-   **Execution**:
    1.  It checks out the `ci-scripts-repository`.
    2.  It dynamically constructs a set of arguments (`CI_ARGS`) based on the job parameters.
    3.  It builds a Docker image using a `Dockerfile` from either `linux_docker_resources` or `windows_docker_resources`. The base OS image within the Dockerfile is dynamically set based on parameters like `CI_UBUNTU_DISTRO`.
    4.  It runs the Docker container, executing the `run_ros2_batch.py` script inside it, passing the `CI_ARGS`. This script performs the actual ROS 2 workspace checkout, build, and test.

### Key Template: `packaging_job.xml.em`

-   **Purpose**: Defines a job that creates distributable packages (e.g., Debian packages).
-   **Agent Label**: Also uses `<assignedNode>@(label_expression)</assignedNode>`.
-   **Execution**: Similar to the `ci_job`, it runs the build inside a Docker container. The main difference is that it passes the `--packaging` flag to the `run_ros2_batch.py` script. It also archives the generated packages (`ws/ros2-package-*.*`) as build artifacts.

### Key Template: `ci_launcher_job.xml.em`

-   **Purpose**: A meta-job that triggers all the other manual `ci_*` jobs.
-   **Agent Label**: Runs on nodes with the label `built-in || master`, which is typically the Jenkins controller itself.
-   **Execution**: This job does not build any code. It uses the **Jenkins Parameterized Trigger Plugin** to start one build for each configured OS (`linux`, `windows`, etc.), passing down the parameters it was given.

## 5. Agent Requirements (Labels)

The script defines the required Jenkins agent labels in the `os_configs` dictionary. The Jenkins master needs to have agents with these corresponding labels available for the jobs to run.

| `os_name`       | `label_expression`       | Description                                  |
| --------------- | ------------------------ | -------------------------------------------- |
| `linux`         | `linux`                  | Standard Linux build agent (x86_64).         |
| `windows`       | `windows-container`      | Windows agent capable of running containers. |
| `windows-2025`  | `windows-2025-container` | Windows Server 2025 container agent.         |
| `linux-aarch64` | `linux_aarch64`          | AArch64 (ARM64) Linux build agent.           |
| `linux-rhel`    | `linux`                  | RHEL-based build agent (runs on a `linux` labeled node but uses a RHEL container). |
| `ci_launcher`   | `built-in \|\| master`   | Can run on the Jenkins controller or any node with the `master` label. |

## 6. Generated Job Types

For each operating system, the script generates a variety of jobs with different purposes:

-   **Manual Jobs**:
    -   `ci_<os_name>`: Manually triggered job to run a standard CI build.
    -   `ci_packaging_<os_name>`: Manually triggered job to run a packaging build.
    -   `ci_<os_name>_clang_libcxx`: Manual job to test compilation with Clang/libc++.
    -   `ci_<os_name>_coverage`: Manual job for code coverage analysis.
-   **Test Jobs**:
    -   `test_*`: Variants of the manual jobs, likely used for validating changes to the job configurations themselves without affecting the primary jobs.
-   **Periodic (Nightly) Jobs**: These are triggered by a cron expression (`0 4 * * *`).
    -   `packaging_<os_name>`: Creates packages from the latest code.
    -   `nightly_<os_name>_debug`: Runs a full build and test in `Debug` mode.
    -   `nightly_<os_name>_release`: Runs a full build and test in `Release` mode.
    -   `nightly_<os_name>_repeated`: Runs tests in a loop until they fail to find flaky tests.
    -   `nightly_<os_name>_xfail`: Runs tests that are expected to fail.
    -   Specialized nightlies for `asan`, `tsan`, `coverage`, and `clang_libcxx` on Linux.
-   **Launcher Job**:
    -   `ci_launcher`: A single job to trigger all manual `ci_*` jobs simultaneously with a consistent set of parameters.
