
# ros-infrastructure/rosdep Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository uses a simple branching strategy with `master` as the main development branch. Feature branches are created for new development and merged into `master` upon completion.

## 2. Core Purpose & Architecture

- **Technical Purpose:** `rosdep` is a command-line tool for installing system dependencies. It is a key component of the ROS (Robot Operating System) ecosystem. It abstracts platform-specific package names, allowing developers to specify dependencies in a platform-agnostic way (e.g., depending on `boost` instead of `libboost-dev` on Debian/Ubuntu).
- **High-Level Architecture:** `rosdep` is a Python-based command-line tool. Its core logic is implemented in the `rosdep2` Python package. It uses a set of YAML files as a database to map abstract dependency names (rosdep keys) to platform-specific package names.

## 3. Consumption (Inputs)

- **External Libraries/Frameworks:**
  - `PyYAML >= 3.1`: For parsing the YAML-based rosdep rules.
  - `importlib_metadata; python_version<"3.8"`: To access package metadata.
  - `catkin_pkg >= 0.4.0`: A Python library for parsing `package.xml` files, which are used to define ROS packages.
  - `rospkg >= 1.4.0`: A Python library for finding and introspecting ROS packages.
  - `rosdistro >= 0.7.5`: A Python library for accessing the ROS distribution files, which contain information about ROS packages and their versions.
- **Other Repositories or Submodules:** The repository does not use submodules. It depends on other ROS infrastructure repositories implicitly through the dependencies listed above.
- **Required APIs or External Services:** `rosdep` downloads its database of dependency rules from YAML files hosted on GitHub (by default, from `https://raw.githubusercontent.com/ros/rosdistro/master/rosdep/sources.list.d/20-default.list`).

## 4. Production (Outputs)

- **Packages:** The repository produces a Python package that is published to PyPI (`rosdep`). It can be installed using `pip`.
- **Binaries/Applications:** The primary output is the `rosdep` command-line tool, which is made available in the user's path after installation.

## 5. CI/CD Pipeline Analysis

- **GitHub Actions:** The repository uses GitHub Actions for CI. The workflow is defined in `.github/workflows/ci.yaml`.
  - **Triggers:** The CI pipeline is triggered on `push` events to the `master` branch and on `pull_request` events.
  - **Jobs:**
    - `pytest`: This job runs the test suite using `pytest`. It uses a reusable workflow from `ros-infrastructure/ci/.github/workflows/pytest.yaml`.
    - `yamllint`: This job checks all YAML files in the repository for style and syntax errors.

## 6. Standalone Usage Guide

A "Quick Start" guide for using `rosdep`:

1.  **Installation:**
    ```bash
    sudo apt-get install python3-rosdep  # On Ubuntu/Debian
    # Or via pip
    sudo pip install -U rosdep
    ```

2.  **Initialization:**
    ```bash
    sudo rosdep init
    rosdep update
    ```

3.  **Usage:**
    -   **Check dependencies:**
        ```bash
        rosdep check <package-name>
        ```
    -   **Install dependencies:**
        ```bash
        rosdep install <package-name>
        ```
    -   **Resolve a rosdep key to a system package:**
        ```bash
        rosdep resolve <rosdep-key>
        ```

## 7. Execution Flow Walkthrough

Here is a detailed walkthrough of the `rosdep install <package-name>` command:

1.  **Entry Point:** The execution starts at the `rosdep_main` function in `src/rosdep2/main.py`, which is the entry point for the `rosdep` command-line tool.

2.  **Argument Parsing:** `_rosdep_main` parses the command-line arguments. For `rosdep install`, the command is `install` and the argument is the package name.

3.  **Command Dispatch:** The `_package_args_handler` function is called for the `install` command. This function is responsible for handling commands that take package or stack names as arguments. It uses `rospkg` to find the location of the specified package and to resolve stack names to a list of packages.

4.  **`command_install` Function:** This function in `src/rosdep2/main.py` is the core of the `install` command's logic.
    -   It creates an `InstallerContext` object, which determines the host OS and the appropriate package manager (e.g., `apt`, `yum`, `brew`). This is done in `src/rosdep2/__init__.py`.
    -   It creates a `RosdepInstaller` object, passing it the `InstallerContext` and a `RosdepLookup` object.

5.  **`RosdepLookup`:** The `RosdepLookup` object is responsible for finding the rosdep definitions. It loads the rosdep database from the cache directory (usually `~/.ros/rosdep/sources.cache`). The database is a collection of YAML files that map rosdep keys to system package names.

6.  **`get_uninstalled`:** The `command_install` function calls `installer.get_uninstalled(packages)`. This method determines which dependencies need to be installed.
    -   It calls `lookup.resolve_all(packages)` to get a list of all rosdep keys for the given packages and their recursive dependencies.
    -   For each rosdep key, it uses the `RosdepLookup` object to find the corresponding system dependency for the current OS.
    -   It then checks if the system dependency is already installed using the appropriate installer (e.g., by running `dpkg -s <package-name>` for `apt`).

7.  **`install`:** Finally, `command_install` calls `installer.install(uninstalled)` to install the missing dependencies.
    -   The `RosdepInstaller` iterates through the list of uninstalled dependencies.
    -   For each dependency, it calls the `install` method of the appropriate installer (e.g., `AptInstaller.install`).
    -   The installer then executes the package manager command to install the package (e.g., `sudo apt-get install <package-name>`).
