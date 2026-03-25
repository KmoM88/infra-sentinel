# Technical Analysis of ros-infrastructure/bloom

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository follows a simple branching strategy. `master` is the main development and release branch. Other branches appear to be for features and bug fixes, which are likely merged into `master` upon completion. There is also a `gh-pages` branch for documentation.

## 2. Core Purpose & Architecture

`bloom` is a release automation tool, primarily used within the ROS (Robot Operating System) ecosystem. It is designed to streamline the process of releasing software from a git repository.

Its main functions are:
- Automating the creation of release branches.
- Generating platform-specific source packages, such as Debian (`.deb`) and RPM (`.rpm`) packages.
- It leverages metadata from `catkin` (a ROS build system) and builds upon the concepts of `git-buildpackage`.

The architecture is a Python-based command-line tool that extends git functionality with a set of `git-bloom-*` and `bloom-*` commands.

## 3. Consumption (Inputs)

The repository consumes the following:

- **External Libraries (Python):**
  - `catkin_pkg`
  - `empy`
  - `importlib-metadata` (for Python < 3.10)
  - `importlib-resources` (for Python < 3.10)
  - `packaging`
  - `python-dateutil`
  - `PyYAML`
  - `rosdep`
  - `rosdistro`
  - `vcstools`

- **External Services:** It interacts with `rosdistro` and `rosdep` which are key infrastructure components in the ROS ecosystem for defining package distributions and system dependencies.

## 4. Production (Outputs)

- **PyPI Package:** The primary output is a Python package distributed on PyPI. This allows users to install `bloom` and its command-line tools using `pip`.
- **Source Packages:** The tool itself produces Debian (`.deb`) and RPM (`.rpm`) source packages for the software it is releasing.
- **Command-Line Tools:** It installs a set of command-line tools, including:
  - `git-bloom-config`
  - `git-bloom-import-upstream`
  - `git-bloom-branch`
  - `git-bloom-patch`
  - `git-bloom-generate`
  - `git-bloom-release`
  - `bloom-export-upstream`
  - `bloom-update`
  - `bloom-release`
  - `bloom-generate`

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for its CI/CD pipeline, defined in `.github/workflows/`.

- **`ci.yaml`:** This workflow is triggered on pushes to `master` and on pull requests. It contains the following jobs:
  - **`pytest`:** Runs the main test suite using a reusable workflow from `ros-infrastructure/ci`. It runs tests across different Python versions and operating systems (excluding Windows).
  - **`pytest-empy-legacy`:** A dedicated job to ensure compatibility with older versions of the `empy` library (`<4`).
  - **`yamllint`:** A linting job to check the syntax of YAML files in the repository.

- **`scheduled.yaml`:** This workflow is likely used to run jobs on a schedule, such as nightly tests, but its content was not inspected in this analysis.

There is no `Jenkinsfile` in the repository, indicating that Jenkins is not used for this project's CI/CD.

## 6. Standalone Usage Guide

To use `bloom` locally, you can install it from PyPI.

**1. Installation:**

```bash
pip install bloom
```

**2. Basic Usage:**

`bloom` is typically used within a git repository of the software you want to release. The general workflow involves the following commands:

- **`git-bloom-import-upstream`**: To import the upstream source code.
- **`git-bloom-branch`**: To create and manage release branches.
- **`git-bloom-generate`**: To generate the release artifacts (e.g., Debian or RPM source packages).
- **`git-bloom-release`**: To perform a release, which may involve tagging and pushing to a remote repository.

For detailed usage, the official documentation should be consulted.
