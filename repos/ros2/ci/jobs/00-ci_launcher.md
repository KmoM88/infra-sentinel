# ci_launcher Job Analysis

## Overview

The `ci_launcher` job is a Jenkins pipeline that serves as the entry point for running ROS 2 builds on multiple platforms. Its primary purpose is to trigger a separate `ci_job` for each supported operating system, passing along a consistent set of parameters. This allows for a centralized way to kick off a full CI run for a given set of changes.

## Job Trigger and Execution Flow

1.  **Trigger:** The `ci_launcher` job is manually triggered, usually by a developer who wants to test a set of changes across all supported platforms.

2.  **Parameters:** The job accepts a wide range of parameters that allow for fine-grained control over the build process. These parameters are detailed in the **Parameters** section below.

3.  **Groovy Script:** The first step in the `ci_launcher` job is to run a Groovy script that predicts the build numbers of the downstream `ci_job` builds that are about to be triggered. It then prints a list of links to these future builds, which provides a convenient way to navigate to the platform-specific build results.

4.  **Downstream Job Triggering:** The `ci_launcher` job uses the "Parameterized Trigger Plugin" to trigger a `ci_job` for each supported platform (e.g., Linux, Windows, macOS, RHEL, aarch64). It passes all of its own parameters to these downstream jobs.

    *   **Special Handling for aarch64:** For the `linux-aarch64` platform, the `CI_USE_CONNEXTDDS` parameter is explicitly set to `false`.
    *   **Special Handling for Windows:** For `windows` and `windows-2025` platforms, the `CI_ISOLATED` parameter is explicitly set.

## `ci_job` - The Downstream Workhorse

The `ci_job` is where the actual build and test process happens. Here's a breakdown of its execution:

1.  **SCM Checkout:** The job checks out the `ros2/ci` repository, using the branch specified by the `CI_SCRIPTS_BRANCH` parameter. This ensures that the build scripts themselves are version-controlled and consistent with the code being tested.

2.  **Docker Environment:** The core of the `ci_job` runs inside a Docker container.

    *   **Dockerfile Selection:** The job selects a Dockerfile based on the target OS:
        *   `linux_docker_resources/Dockerfile` for generic Linux.
        *   `linux_docker_resources/Dockerfile-RHEL` for RHEL.
        *   `windows_docker_resources/Dockerfile` for Windows.
    *   **Dockerfile Modification:** The Linux Dockerfiles are dynamically modified to use the Ubuntu distribution or RHEL release specified by the `CI_UBUNTU_DISTRO` or `CI_EL_RELEASE` parameters.
    *   **Docker Image Build:** A new Docker image is built for each job run. This ensures a clean and consistent build environment. The image is tagged with a name like `ros2_batch_ci`, `ros2_batch_ci_aarch64`, or `ros2_batch_ci_rhel`.
    *   **Docker Container Run:** The job runs the newly built Docker image, mounting the Jenkins workspace and the `.ccache` directory into the container. It passes a large number of arguments to the container via the `CI_ARGS` environment variable.

3.  **`run_ros2_batch.py` and `ros2_batch_job`:** Inside the Docker container, the `run_ros2_batch.py` script is executed. This script is an entry point for the `ros2_batch_job` Python module, which contains the main logic for the build process.

    *   **Repository Fetching:** `ros2_batch_job` uses `vcstool` to fetch the ROS 2 source code from the `.repos` file specified by the `CI_ROS2_REPOS_URL` parameter. It can also merge a supplemental `.repos` file and check out a specific branch for testing.
    *   **Package Blacklisting:** It can ignore specific ROS 2 packages by creating `COLCON_IGNORE` files in their source directories. This is primarily used to disable certain RMW (ROS Middleware) implementations.
    *   **Build and Test:** The script then uses `colcon` to build and test the workspace.
        *   `colcon build`: Compiles the code. The build type (e.g., `Debug`, `Release`) and other CMake arguments can be controlled by job parameters.
        *   `colcon test`: Runs the tests.
        *   `colcon test-result`: Collects and summarizes the test results.
    *   **Coverage:** If enabled, the build is instrumented for code coverage. After the tests are run, `lcov` is used to generate a coverage report, which is then converted to the Cobertura format for display in Jenkins.

## Configuration and Scripts

*   **Jenkins Job Templates:**
    *   `job_templates/ci_launcher_job.xml.em`: The template for the `ci_launcher` job.
    *   `job_templates/ci_job.xml.em`: The template for the `ci_job`.
    *   `job_templates/snippet/`: This directory contains various snippets that are included in the main job templates, such as parameter definitions and publisher configurations.
*   **Build Logic:**
    *   `run_ros2_batch.py`: The entry point for the build process inside the Docker container.
    *   `ros2_batch_job/`: The Python module containing the core build and test logic. `__main__.py` is the main script.
*   **Docker configuration:**
    *   `linux_docker_resources/Dockerfile`: The main Dockerfile for Linux builds.
    *   `linux_docker_resources/Dockerfile-RHEL`: The Dockerfile for RHEL builds.
    *   `windows_docker_resources/Dockerfile`: The Dockerfile for Windows builds.

## Parameters

The `ci_launcher` job (and by extension, the `ci_job`) accepts a large number of parameters. Here are some of the most important ones:

*   **Repository and Branch Control:**
    *   `CI_ROS2_REPOS_URL`: The URL of the `.repos` file to use for the build. This is the primary way to specify the set of repositories and branches to be tested.
    *   `CI_ROS2_SUPPLEMENTAL_REPOS_URL`: A supplemental `.repos` file to be merged with the main one.
    *   `CI_BRANCH_TO_TEST`: A branch to check out on all repositories that have it.
    *   `CI_SCRIPTS_BRANCH`: The branch of the `ros2/ci` repository to use for the build scripts.
    *   `CI_COLCON_BRANCH`: A specific branch of the `colcon` repositories to use.

*   **Build Configuration:**
    *   `CI_CMAKE_BUILD_TYPE`: The CMake build type (e.g., `Debug`, `Release`, `RelWithDebInfo`).
    *   `CI_ISOLATED`: Whether to build packages in isolation.
    *   `CI_COMPILE_WITH_CLANG`: Whether to use Clang instead of GCC on Linux.
    *   `CI_ENABLE_COVERAGE`: Whether to enable code coverage analysis.
    *   `CI_BUILD_ARGS`: Arbitrary arguments to pass to `colcon build`.
    *   `CI_TEST_ARGS`: Arbitrary arguments to pass to `colcon test`.

*   **Platform and RMW Control:**
    *   `CI_UBUNTU_DISTRO`: The Ubuntu distribution to use for Linux builds.
    *   `CI_EL_RELEASE`: The RHEL release to use for RHEL builds.
    *   `CI_USE_CONNEXTDDS`, `CI_USE_CYCLONEDDS`, `CI_USE_FASTRTPS_STATIC`, `CI_USE_FASTRTPS_DYNAMIC`: Boolean flags to enable or disable specific RMW implementations.

*   **Path and Workspace Control:**
    *   `CI_USE_WHITESPACE_IN_PATHS`: If `true`, whitespace is added to workspace paths to test for robustness.
