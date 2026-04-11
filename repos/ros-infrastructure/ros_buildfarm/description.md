# ros-infrastructure/ros_buildfarm Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository uses a `master` branch for the latest stable version. There are a number of feature and bugfix branches, as well as a `3.x` branch that appears to be a long-term support release.

## 2. Core Purpose & Architecture

`ros_buildfarm` is a Python-based tool for automating the process of building ROS (Robot Operating System) packages. It generates Jenkins jobs or shell scripts that can be run locally. The architecture is based on Docker, with each step of the build process running in a separate container.

The system is highly configurable and uses a separate repository, [`ros-infrastructure/ros_buildfarm_config`](https://github.com/ros-infrastructure/ros_buildfarm_config), to define the build configurations for different ROS distributions.

## 3. Consumption (Inputs)

- **External Libraries:**
    - `empy`: A templating library used for processing templates.
    - `PyYAML`: For parsing YAML configuration files.
    - `catkin_pkg`: A library for working with catkin packages.
    - `jenkinsapi`: A Python API for interacting with the Jenkins CI server.
    - `rosdistro`: A library for managing ROS distributions.
    - `vcstool`: A tool for managing multiple version control repositories.
- **Other Repositories:** The repository consumes configuration from the [`ros-infrastructure/ros_buildfarm_config`](https://github.com/ros-infrastructure/ros_buildfarm_config) repository.
- **APIs:** The `jenkinsapi` library is used to interact with the Jenkins API for creating and managing jobs.

## 4. Production (Outputs)

- **Python Package:** The repository produces a Python package that can be installed via `pip`.
- **Debian Packages:** `stdeb.cfg` is present, which indicates that the repository can be packaged as a Debian package.
- **Jenkins Jobs:** The primary output of the tool is a set of Jenkins jobs for building ROS packages.
- **Shell Scripts:** The tool can also generate shell scripts for running builds locally.

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for its CI/CD pipeline. The workflow is defined in `.github/workflows/ci.yaml`.

- **Triggers:** The CI pipeline is triggered on `push` events to the `master` branch and on `pull_request` events.
- **Jobs:** The pipeline consists of a number of jobs, including:
    - `pytest`: Runs the test suite using `pytest`.
    - `ros1_audit` / `ros2_audit`: Audits the ROS 1 / ROS 2 configurations.
    - `ros1_config` / `ros2_config`: Validates the build configurations.
    - `ros1_doc` / `ros2_doc`: Generates documentation for ROS packages.
    - `ros1_prerelease` / `ros2_prerelease`: Runs pre-release tests.
    - `ros1_release` / `ros2_release`: Creates releases of ROS packages.
    - `ros1_status_pages` / `ros2_status_pages`: Generates status pages for the build farm.

## 6. Standalone Usage Guide

To run the `ros_buildfarm` scripts locally, you can install the package and its dependencies using `pip`:

```bash
pip install .
```

You can then run the scripts from the `scripts` directory. For example, to generate all jobs for a given ROS distribution:

```bash
./scripts/generate_all_jobs.py <config_url> <ros_distro>
```

Refer to the `README.md` and the `doc` directory for more detailed instructions.

## 7. Execution Flow Walkthrough

The most common use case for `ros_buildfarm` is generating Jenkins jobs for a ROS distribution. Here's a high-level walkthrough of the execution flow:

1.  **Entry Point:** The user invokes one of the scripts in the `scripts` directory, such as `scripts/generate_all_jobs.py`.

2.  **Configuration Loading:** The script loads the build configuration from the `ros_buildfarm_config` repository. This configuration is defined in YAML files and specifies the ROS distribution, target platforms, and other build parameters. The loading of the configuration is handled by the `ros_buildfarm.config` module.

3.  **Job Generation:** The script iterates through the build configuration and generates Jenkins jobs for each package and target platform. The job generation logic is implemented in the `ros_buildfarm.release_job`, `ros_buildfarm.devel_job`, `ros_buildfarm.ci_job`, and `ros_buildfarm.doc_job` modules. These modules use the `empy` templating library to generate the Jenkins `config.xml` files from templates located in the `ros_buildfarm/templates` directory.

4.  **Jenkins Integration:** The generated job configurations are then sent to the Jenkins server using the `jenkinsapi` library. The `ros_buildfarm.jenkins` module provides helper functions for interacting with the Jenkins API.

5.  **Output:** The final output is a set of Jenkins jobs that are configured to build the ROS packages for the specified distribution and target platforms.
