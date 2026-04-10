# `colcon/colcon-core` Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository follows a standard feature-branch workflow. Developers create branches off `master` to work on new features or fixes. Pull requests are then opened to merge the changes back into `master`.

## 2. Core Purpose & Architecture

`colcon-core` is the central package for the `colcon` command-line tool. `colcon` (collective construction) is an extensible tool for building, testing, and using sets of software packages. It is widely used in the ROS (Robot Operating System) community but is designed to be generic and support various package types.

The architecture of `colcon` is highly modular and based on a plugin system using `setuptools` entry points. The core functionality is kept minimal, and most features are provided by extensions. This allows `colcon` to be adapted to different build systems and workflows.

The main components of the architecture are:

- **Verbs:** These are the subcommands for `colcon` (e.g., `build`, `test`). Each verb is an extension point.
- **Tasks:** These are the actions that can be performed on a package (e.g., building, testing). There are different task extensions for different package types (e.g., CMake, Python).
- **Executors:** These plugins are responsible for running the tasks in the correct order, potentially in parallel.
- **Event Handlers:** These plugins handle the events that occur during the execution of a command, such as logging and displaying progress.
- **Package Discovery and Identification:** These extensions are responsible for finding packages in the workspace and determining their type and dependencies.

## 3. Consumption (Inputs)

- **External Libraries/Frameworks:** The dependencies are listed in the `setup.cfg` file and include:
  - `coloredlogs` (for Windows)
  - `distlib`
  - `EmPy`
  - `importlib-metadata` (for Python < 3.8)
  - `packaging`
  - `pytest`
  - `pytest-cov`
  - `pytest-repeat`
  - `pytest-rerunfailures`
  - `setuptools`
  - `tomli` (for Python < 3.11)
- **Other Repositories:** The CI/CD pipeline references the `colcon/ci` repository for shared workflows.
- **APIs or External Services:** No external APIs are required for the core functionality of the tool.

## 4. Production (Outputs)

- **PyPI Package:** The repository is set up to be packaged and distributed on PyPI as `colcon-core`.
- **Debian Package:** The `setup.py` and `stdeb.cfg` files indicate that it can also be built as a Debian package.
- **Compiled Binaries:** The repository does not produce any compiled binaries itself.

## 5. CI/CD Pipeline Analysis

The CI/CD pipeline is defined using GitHub Actions in the `.github/workflows` directory.

- **`ci.yaml`**: This is the main workflow that triggers on pushes to `master` and on pull requests. It has two jobs:
  - `pytest`: This job uses a reusable workflow from the `colcon/ci` repository to run tests with `pytest`. It also uploads code coverage reports to Codecov.
  - `bootstrap`: This job uses the `bootstrap.yaml` workflow in the same repository.

- **`bootstrap.yaml`**: This is a reusable workflow that performs a "bootstrap" test. It builds and tests `colcon-core` using a version of `colcon` from the workspace itself. This ensures that the tool is self-hosting. The workflow runs on a matrix of operating systems and Python versions.

## 6. Standalone Usage Guide

To use `colcon-core` locally, you can install it from source.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/colcon/colcon-core.git
    cd colcon-core
    ```

2.  **Install dependencies and the package in editable mode:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -e .
    ```

3.  **Run `colcon`:**
    ```bash
    colcon --help
    ```

## 7. Execution Flow Walkthrough

The following is a step-by-step walkthrough of the `colcon build` command:

1.  **Entry Point:** The execution starts at the `main` function in `colcon_core/command.py`, which is registered as a `console_script` in `setup.cfg`.

2.  **Argument Parsing:** The `main` function calls `_main`, which sets up logging and then creates the main argument parser. It discovers available "verbs" (like `build`) by looking for extensions registered under the `colcon_core.verb` entry point. It parses the command line to identify the verb and then adds the specific arguments for that verb.

3.  **Verb Invocation:** The `_main` function then calls `verb_main`, which in turn calls the `main` method of the selected verb's extension class. For `colcon build`, this is the `main` method of the `BuildVerb` class in `colcon_core/verb/build.py`.

4.  **Package Discovery:** The `BuildVerb.main` method calls `get_packages`. This function discovers all packages in the workspace by using package discovery extensions. It also determines the dependencies between packages.

5.  **Job Creation:** The `BuildVerb.main` method then calls `_get_jobs`. This method iterates through the discovered packages and creates a `Job` for each one that needs to be built.
    - It uses task extensions (e.g., for Python packages, CMake packages, etc.) to create the appropriate build steps for each package.
    - Each `Job` has a set of dependencies on other jobs, which ensures that packages are built in the correct order.

6.  **Job Execution:** The `BuildVerb.main` method calls `execute_jobs`. This function uses an executor extension (e.g., `sequential` or `parallel`) to run the jobs. The executor calls the `build` method of the task extension for each job.

7.  **Prefix Script Creation:** After all jobs have been executed, `BuildVerb.main` calls `_create_prefix_scripts`. This method uses shell extensions to create environment setup scripts (e.g., `local_setup.bash`) in the install directory. These scripts can be sourced to use the newly built packages.
