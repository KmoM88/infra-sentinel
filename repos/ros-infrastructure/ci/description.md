# Technical Analysis of ros-infrastructure/ci

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `main`
- **Branching Strategy:** The repository follows a standard development model with `main` as the primary branch for the latest stable version. No complex branching strategies like GitFlow are in use.

## 2. Core Purpose & Architecture

The `ros-infrastructure/ci` repository provides a reusable **composite GitHub Action** designed to standardize Continuous Integration (CI) for Python-based projects, particularly within the `ros-infrastructure` ecosystem.

Its core purpose is to:
- Set up a consistent Python environment.
- Install dependencies using a shared set of constraints.
- Execute tests using `pytest`.
- Generate code coverage reports.

Architecturally, it is not a standalone application but a modular and reusable CI component intended to be consumed by other GitHub Actions workflows.

## 3. Consumption (Inputs)

The action is designed to be triggered within a CI pipeline and consumes the following:

- **Python Dependencies:** Dependencies are managed via `pip` and constraint files.
  - `constraints.txt`: The main constraints file, which includes `constraints-heads.txt` and `constraints-pins.txt`.
  - `constraints-heads.txt`: References the `HEAD` (master/main) versions of key `ros-infrastructure` and `osrf` repositories, ensuring integration testing against the latest code.
- **GitHub Actions Inputs:** The `pytest.yaml` reusable workflow defines several inputs to control its behavior:
  - `repository`: The target repository to test (e.g., `ros-infrastructure/rosdistro`).
  - `matrix-filter`: A `jq` filter to select specific configurations from the `strategy.json` build matrix.
  - `codecov`: A boolean to enable/disable uploading coverage reports to Codecov.
- **Source Code:** The action checks out the source code of the specified `repository` to run tests on it.

## 4. Production (Outputs)

- **Reusable GitHub Action:** The primary output is the GitHub Action itself (`ros-infrastructure/ci@main`), which can be incorporated into any workflow.
- **CI Artifacts:**
  - **Test Results:** A pass or fail status for the CI job.
  - **Code Coverage:** A `coverage.xml` file is generated, which can be consumed by services like Codecov.

## 5. CI/CD Pipeline Analysis

The repository dogfoods its own action for CI. The testing infrastructure is defined in the `.github/workflows/` directory.

- **`.github/workflows/pytest.yaml`:** This is a **reusable workflow** that defines the main test pipeline.
  - It uses a matrix strategy defined in `strategy.json` to run tests across multiple operating systems (`macos-latest`, `ubuntu-latest`, `windows-latest`) and Python versions.
  - It checks out the target repository and the `ci` repository itself (to access the action).
  - It then executes the composite action (`uses: ./.github-ci-action-repo`).
- **`.github/workflows/ci.yaml`:** This workflow serves as a "canary" test for the `pytest.yaml` workflow.
  - It is triggered on pushes and pull requests to `main`.
  - It calls the `pytest.yaml` workflow, targeting the `ros-infrastructure/rosdistro` repository to perform a live integration test of the CI action.
  - It also runs `yamllint` to ensure the YAML files in the repository are well-formed.

## 6. Standalone Usage Guide

To use this action in a project's CI pipeline, you would reference it in your workflow file.

### Quick Start Example

Here is a basic example of how to integrate the action into a `.github/workflows/main.yaml` file:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # 1. Checkout your repository's code
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. Setup Python environment
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      # 3. Checkout the ci action repository
      - name: Checkout ci action
        uses: actions/checkout@v4
        with:
          repository: ros-infrastructure/ci
          path: ./.github-ci-action-repo

      # 4. Run the tests using the composite action
      - name: Run pytest
        uses: ./.github-ci-action-repo
```

## 7. Execution Flow Walkthrough

The typical execution flow is initiated by a workflow in another repository (or the `ci.yaml` workflow within this repo) that calls the `pytest.yaml` reusable workflow.

1.  **Trigger:** A `push` or `pull_request` event triggers the `ci.yaml` workflow in `ros-infrastructure/ci`.

2.  **Canary Job (`.github/workflows/ci.yaml`):**
    - The `canary` job is initiated.
    - It calls the reusable workflow `pytest.yaml` (`uses: ./.github/workflows/pytest.yaml`).
    - It passes `ros-infrastructure/rosdistro` as the `repository` input to be tested.

3.  **Setup Job (`.github/workflows/pytest.yaml`):**
    - The `setup` job in `pytest.yaml` runs first.
    - It checks out the `ros-infrastructure/ci` repository.
    - It reads the `strategy.json` file to determine the build matrix (OS and Python versions).
    - It outputs the `strategy` as a JSON string for the next job.

4.  **Pytest Job (`.github/workflows/pytest.yaml`):**
    - This job runs for each configuration in the matrix defined by the `setup` job.
    - **Step 1: Checkout Target Repo:** It checks out the code of the repository specified in the `repository` input (e.g., `ros-infrastructure/rosdistro`).
    - **Step 2: Setup Python:** It uses `actions/setup-python@v5` to install the specified Python version from the matrix.
    - **Step 3: Checkout Action Repo:** It checks out the `ros-infrastructure/ci` repository into a local directory named `./.github-ci-action-repo`.
    - **Step 4: Execute Composite Action:** It executes the composite action located at `./.github-ci-action-repo`. This triggers the steps defined in `action.yaml`.

5.  **Composite Action Steps (`action.yaml`):**
    - **Step 1: Initialize Environment:** A Python virtual environment is created and activated. `pip` and `setuptools` are updated.
    - **Step 2: Install Package:** It installs the target repository's package in editable mode (`-e .[test]`). The `--no-deps` flag is used because dependencies will be handled in the next step.
    - **Step 3: Install Dependencies:**
        - It copies the `constraints.txt`, `constraints-heads.txt`, and `constraints-pins.txt` files to the working directory.
        - It installs the dependencies (including `test` extras and `pytest-cov`) using the combined constraints files (`-c constraints.txt`). This ensures that all packages in the `ros-infrastructure` ecosystem are tested against compatible versions.
    - **Step 4: Run Tests:**
        - It executes `pytest` with the following options:
            - `--cov --cov-branch`: Enables code coverage collection, including branch coverage.
            - `--cov-report xml:coverage.xml`: Generates a coverage report in XML format.
            - `--cov-config setup.cfg`: Specifies the configuration file for coverage analysis.

6.  **Codecov Step (`.github/workflows/pytest.yaml`):**
    - If `inputs.codecov` is `true`, the `codecov/codecov-action@v4` action runs.
    - It finds the `coverage.xml` file and uploads it to Codecov for analysis and reporting.
