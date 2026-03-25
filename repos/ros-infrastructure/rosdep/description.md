# Technical Analysis of ros-infrastructure/rosdep

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository uses a simple branching model where `master` is the main development branch. Other branches are used for feature development and bug fixes, which are then merged into `master`.

## 2. Core Purpose & Architecture

`rosdep` is a command-line utility that serves as a package manager abstraction tool for ROS (Robot Operating System). Its primary purpose is to simplify the installation of system-level dependencies for ROS packages.

- **For end-users:** It automatically installs the required system libraries needed to compile ROS packages from source.
- **For developers:** It provides a platform-agnostic way to declare system dependencies for their packages. For example, instead of specifying `libboost-dev` for Debian-based systems, a developer can simply declare a dependency on `boost`, and `rosdep` will resolve and install the correct package for the user's operating system.

The architecture is a Python-based command-line tool that is distributed as a PyPI package.

## 3. Consumption (Inputs)

The repository has the following dependencies:

- **External Libraries (Python):**
  - `PyYAML >= 3.1`
  - `importlib_metadata` (for Python < 3.8)
  - `catkin_pkg >= 0.4.0` (conditional)
  - `rospkg >= 1.4.0` (conditional)
  - `rosdistro >= 0.7.5` (conditional)

- **External Services:** `rosdep` relies on the `rosdistro` database, which contains the mapping of `rosdep` keys (like `boost`) to system packages for various operating systems and distributions. This database is typically hosted in a git repository.

## 4. Production (Outputs)

- **PyPI Package:** The main output is a Python package published to PyPI, which can be installed using `pip`.
- **Command-Line Tools:** The package installs two command-line scripts:
  - `rosdep`: The main tool for managing system dependencies.
  - `rosdep-source`: A helper tool for installing dependencies from source.
- **Debian Package:** The `stdeb.cfg` file indicates that this package is also intended to be released as a Debian package.

## 5. CI/CD Pipeline Analysis

The project uses GitHub Actions for its CI pipeline, defined in `.github/workflows/ci.yaml`.

- **`ci.yaml`:** This workflow is triggered on pushes to the `master` branch and on pull requests. It consists of two jobs:
  - **`pytest`:** This job runs the test suite using a reusable workflow from the `ros-infrastructure/ci` repository. It runs tests on various Python versions and operating systems (excluding Windows) and uploads coverage reports to Codecov.
  - **`yamllint`:** This job performs linting on all YAML files in the repository to ensure they adhere to style guidelines.

There is no `Jenkinsfile`, indicating that Jenkins is not part of this project's CI/CD process.

## 6. Standalone Usage Guide

To use `rosdep` locally, it must first be initialized.

**1. Installation:**

```bash
sudo apt-get install python3-rosdep # Recommended on Ubuntu
# OR
sudo pip install -u rosdep
```

**2. Initialization:**

`rosdep` must be initialized before it can be used.

```bash
sudo rosdep init
rosdep update
```

**3. Basic Usage:**

`rosdep` is most commonly used to install the dependencies of a ROS workspace.

```bash
# In the root of a ROS workspace
rosdep install --from-paths src --ignore-src -r -y
```

This command will read the `package.xml` files in the `src` directory, identify the system dependencies, and install them using the system's package manager (e.g., `apt-get` on Debian/Ubuntu).
