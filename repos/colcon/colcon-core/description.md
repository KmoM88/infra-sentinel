# Technical Analysis of colcon/colcon-core

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `master`. The branching strategy appears to follow a feature-based development model. Numerous branches exist, most of which seem to be individual feature or experimental branches, rather than a structured GitFlow (`dev`/`staging`/`prod`) model.

## 2. Core Purpose & Architecture

The repository hosts `colcon-core`, a command-line tool designed to build, test, and use multiple software packages collectively. It is particularly prevalent in the ROS (Robot Operating System) ecosystem. Its architecture is modular and extensible, relying on a system of entry points and plugins. The core provides the main functionality and extension points for other packages to hook into, allowing for customized build, test, and discovery logic. The system is written in Python.

## 3. Consumption (Inputs)

The repository's dependencies are managed in `setup.cfg`.

*   **External Libraries/Frameworks:**
    *   `coloredlogs`
    *   `distlib`
    *   `EmPy`
    *   `importlib-metadata` (for Python < 3.8)
    *   `packaging`
    *   `pytest`
    *   `pytest-cov`
    *   `pytest-repeat`
    *   `pytest-rerunfailures`
    *   `setuptools`
    *   `tomli` (for Python < 3.11)
*   **Other Repositories:** The CI/CD pipeline references `colcon/ci` for a reusable workflow, indicating a dependency on this repository for integration testing.
*   **APIs or External Services:** No external APIs are directly consumed by the core logic of the tool itself.

## 4. Production (Outputs)

This repository produces a Python package, which is published to PyPI (Python Package Index). The primary output is a console script executable named `colcon`. It does not produce a compiled binary or a served web application.

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for its CI/CD pipeline. No `Jenkinsfile` was found. The workflows are defined in the `.github/workflows/` directory.

*   **`ci.yaml`:** This is the main workflow, triggered on `push` events to the `master` branch and on any `pull_request`. It calls two other workflows:
    1.  `colcon/ci/.github/workflows/pytest.yaml@main`: A reusable workflow from an external repository (`colcon/ci`) that runs `pytest` to execute the test suite. It uses a `CODECOV_TOKEN` secret, implying that it uploads coverage reports to Codecov.
    2.  `./.github/workflows/bootstrap.yaml`: A local reusable workflow that performs a series of bootstrap tests.

*   **`bootstrap.yaml`:** This workflow is designed to be reusable. It performs the following stages:
    1.  **Setup:** Checks out `colcon/ci` to get a testing strategy matrix.
    2.  **Bootstrap:** For each configuration in the strategy matrix (different OS and Python versions), it performs the following steps:
        *   Checks out the `colcon-core` repository.
        *   Sets up the specified Python version.
        *   Installs dependencies and the `colcon-core` package in editable mode.
        *   Uninstalls `colcon-core` to ensure the next steps use the newly built version.
        *   Builds and tests the package from a parent directory using the `colcon` script from the repository's `bin` directory.
        *   Verifies that the installed package is accessible by sourcing the appropriate setup script (`local_setup.sh` or `local_setup.bat`) and running `colcon --help`.

## 6. Standalone Usage Guide

To run or use this repository locally, a developer would typically follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/colcon/colcon-core.git
    cd colcon-core
    ```

2.  **Install dependencies and the package in editable mode:**
    This allows you to run the `colcon` command from your terminal and have your changes to the source code be reflected immediately.
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -e .
    ```

3.  **Run the tool:**
    Once installed, you can use the `colcon` command line tool.
    ```bash
    colcon --help
    ```
