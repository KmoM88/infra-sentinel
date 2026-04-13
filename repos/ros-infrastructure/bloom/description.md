# Technical Analysis of ros-infrastructure/bloom

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `master`. The branching strategy appears to be a form of GitFlow where `master` is the main development branch. Other branches are used for features, bugfixes, and GitHub pages (`gh-pages`).

## 2. Core Purpose & Architecture

`bloom` is a Python-based command-line tool designed to automate the software release process, with a specific focus on [ROS (Robot Operating System)](http://www.ros.org/) packages. It streamlines the creation of release branches, the generation of platform-specific source packages (e.g., Debian `src-debs`), and the management of releases in `git-buildpackage` repositories.

The architecture is that of a modular command-line tool. The core logic is implemented in the `bloom` Python package, which is then exposed to the user through a set of console scripts defined in `setup.py`.

## 3. Consumption (Inputs)

`bloom` consumes the following inputs:

*   **External Libraries/Frameworks**: As defined in `setup.py`, the main dependencies are:
    *   `catkin_pkg`: For parsing ROS package metadata.
    *   `empy`: A templating library.
    *   `packaging`: For package versioning and metadata.
    *   `python-dateutil`: For parsing dates.
    *   `PyYAML`: For parsing YAML files.
    *   `rosdep`: For managing ROS system dependencies.
    *   `rosdistro`: For interacting with ROS distribution files.
    *   `vcstools`: For abstracting version control system operations.
    *   `importlib-metadata` and `importlib-resources` for older python versions.

*   **Configuration Files**: It relies on a `tracks.yaml` file within a release repository to manage release configurations. It can also interact with ROS distribution files (`.yaml` files that define the packages in a ROS distribution).

## 4. Production (Outputs)

The repository produces:

*   **A Python Package**: It is packaged using `setuptools` and can be installed from PyPI (`pip install bloom`).
*   **Automated Release Artifacts**: Its primary output is not a compiled binary but the automation of release workflows. This includes:
    *   Creating and pushing git branches and tags.
    *   Generating pull requests on GitHub to update `rosdistro` files.

## 5. CI/CD Pipeline Analysis

The repository uses **GitHub Actions** for its CI/CD pipeline.

*   **Workflows**: The CI pipeline is defined in `.github/workflows/ci.yaml`.
*   **Triggers**: The workflow is triggered on `push` events to the `master` branch and on `pull_request` events.
*   **Jobs**: The pipeline consists of the following main jobs:
    *   `pytest`: Runs the test suite using `pytest`. It is configured to run on different operating systems, excluding Windows.
    *   `pytest-empy-legacy`: A dedicated job to ensure compatibility with older versions of the `empy` library.
    *   `yamllint`: Lints all YAML files in the repository.

## 6. Standalone Usage Guide

A developer can use this repository as a command-line tool.

1.  **Installation**:
    *   From PyPI: `pip install bloom`
    *   From source:
        ```bash
        git clone https://github.com/ros-infrastructure/bloom.git
        cd bloom
        pip install .
        ```

2.  **Usage**: `bloom` provides several commands, which are registered as console scripts in `setup.py`. A typical command to perform a release is:

    ```bash
    bloom-release --ros-distro <distro_name> --track <track_name> <repository_name>
    ```

## 7. Execution Flow Walkthrough

A typical execution flow for `bloom` is releasing a package. The `bloom-release` command is a good example to trace.

1.  **Entry Point**: The user executes the `bloom-release` command. This script is an entry point defined in `setup.py`, which calls the `main` function in `bloom/commands/release.py`.

2.  **Argument Parsing**: The `main` function in `bloom/commands/release.py` uses `argparse` to parse the command-line arguments provided by the user, such as the repository to release, the ROS distribution, and the release track.

3.  **Core Logic**: The `main` function then calls `perform_release`, which is the core of the release process.

4.  **Release Repository and Track Handling**: `perform_release` starts by getting the release repository using `get_release_repo`. It then handles the creation or selection of a release track. A track defines how a release should be performed.

5.  **Performing the Release**: If not in `--pull-request-only` mode, `perform_release` calls `_perform_release`. This function executes the `git-bloom-release` command (another entry point), which performs the main release tasks: creating release branches, tagging, and committing changes.

6.  **Pushing Changes**: After the release is done, `_perform_release` pushes the new branches and tags to the remote release repository.

7.  **Generating a Pull Request**: Back in `perform_release`, if not disabled, it proceeds to open a pull request against the `rosdistro` repository. This is done by calling `open_pull_request`.

8.  **Pull Request Creation**: `open_pull_request` generates a diff for the `rosdistro` file (a YAML file that lists all packages in a ROS distribution) and then uses the GitHub API to create a pull request with this change. This updates the ROS distribution to point to the new release of the package.
