# Technical Analysis of ros-infrastructure/ci

This document provides a deep technical analysis of the `ros-infrastructure/ci` GitHub repository.

### 1. Repository Discovery & Branching Logic

The `ros-infrastructure/ci` repository is not a traditional application or library, but a **reusable composite GitHub Action**. Its primary purpose is to provide a standardized CI testing step for other Python-based repositories within the ROS infrastructure ecosystem.

**Branching Strategy:**

-   **Primary Branch**: The repository uses a `main` branch for its development.
-   **Strategy**: There are no long-lived alternative branches (like `dev` or release branches). Development follows a typical trunk-based model where changes are merged directly into `main`. Consumers of this action would typically pin to a specific commit hash or a version tag (e.g., `v1`) for stability, though none are present yet.

### 2. Core Purpose & Architecture

**Core Purpose:**

The repository provides a single, reusable GitHub Action named **"ros-infrastructure pytest"**. Its purpose is to standardize the process of testing Python packages with `pytest` across the `ros-infrastructure` projects. It solves the problem of CI configuration duplication by encapsulating the entire test execution logic—environment setup, dependency installation, and test invocation—into a single, versionable component.

**High-Level Architecture:**

The architecture is that of a **composite GitHub Action**, defined in `action.yaml`. It is designed to be executed as a step within a larger GitHub Actions workflow in a consuming repository. Its internal logic is a sequence of shell commands:

1.  **Environment Initialization**: Creates a temporary Python virtual environment (`venv`).
2.  **Package Installation**: Installs the package from the consuming repository in editable mode (`pip install -e .[test]`).
3.  **Dependency Management**: Installs the package's dependencies using pinned versions from the `constraints.txt` files, ensuring a reproducible build.
4.  **Test Execution**: Runs `pytest` with code coverage enabled (`--cov`) and generates an XML coverage report.

### 3. Consumption (Inputs)

As a GitHub Action, its primary inputs are the context provided by the workflow that calls it.

-   **Consuming Repository's Code**: The action implicitly operates on the source code of the repository that uses it in a workflow. It assumes a Python package with a `setup.py` or `setup.cfg` that defines an installable package with a `[test]` extra.
-   **Python Dependencies**: It uses `constraints.txt`, `constraints-heads.txt`, and `constraints-pins.txt` from its own repository to lock down versions of Python packages for the test run.
-   **Self-Testing Dependencies**: For its own CI (testing the action itself), it uses the `ros-infrastructure.repos` file to check out other tools like `bloom`, `rosdep`, and `ros_buildfarm`. These are *not* dependencies when the action is used in another repository.

### 4. Production (Outputs)

The "product" of this action is the outcome of the CI test step within a consuming workflow.

-   **Test Results**: The action's primary output is the pass/fail status of the `pytest` run. A failing test run will cause the GitHub Actions step to fail.
-   **Code Coverage Report**: It produces a `coverage.xml` file, which can be consumed by other tools or workflow steps (e.g., uploading the report to Codecov or a similar service).
-   **No Deployed Artifacts**: This repository does not produce any deployed packages, images, or binaries itself. It is purely a process automation tool.

### 5. CI/CD Pipeline Analysis

The repository contains a CI pipeline in `.github/workflows/` designed to **test the action itself**.

-   **`pytest.yaml`**: This is the main CI workflow. It is triggered on pull requests and pushes to the `main` branch.
    -   **Strategy Matrix**: It uses a matrix strategy defined in `strategy.json` to run jobs across multiple operating systems (`macos`, `ubuntu`, `windows`) and a wide range of Python versions (`3.8` through `3.14`). This ensures the action is robust and cross-platform compatible.
    -   **Self-Usage**: The core of the workflow is a step `uses: ./`, which executes the `action.yaml` from the repository's own root. This is a common pattern for testing reusable GitHub Actions.

### 6. Standalone Usage Guide

This repository is not run "standalone" in a traditional sense. It is meant to be consumed by a GitHub Actions workflow in another repository.

Here is a "Quick Start" guide for a developer to **use this action** in their own project's CI workflow.

**File: `.github/workflows/main.yaml`**

```yaml
name: CI

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      # Use the ros-infrastructure/ci action to run pytest
      - name: Run pytest
        uses: ros-infrastructure/ci@main # Or pin to a specific commit/tag

      # Optional: Upload coverage report produced by the action
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml # The file generated by the previous step
```