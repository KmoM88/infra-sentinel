# Technical Analysis of colcon/ci

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `main`. The branching strategy is simple, with `main` serving as the stable trunk. Other branches appear to be for dependency updates (managed by `dependabot`) or feature development.

## 2. Core Purpose & Architecture

This repository is the heart of the `colcon` organization's Continuous Integration (CI) infrastructure. It does not contain a software package itself, but rather a set of **reusable GitHub Actions workflows and configurations** designed to standardize the testing and publishing of all other `colcon` packages.

The architecture is centered around a **composite GitHub Action** defined in `action.yaml`. This action encapsulates the entire CI process for a typical `colcon` Python package. This approach allows the `colcon` project to maintain a single, canonical CI process that can be easily updated and applied across all of its repositories.

Key components of the architecture include:
-   **Reusable Workflows:** A `pytest.yaml` workflow is provided for other repositories to call via the `uses:` syntax in their own CI files.
-   **Composite Action:** The `action.yaml` file defines the main "colcon pytest" action, which performs all the steps from setting up a Python environment to running tests and simulating package publication.
-   **Shared Configuration:** The repository contains shared configuration files that are used by the composite action across all `colcon` projects. These include:
    -   `constraints.txt`: Pins the versions of common Python dependencies to ensure a consistent testing environment.
    -   `strategy.json`: Defines build matrices for running tests across different operating systems and Python versions.

## 3. Consumption (Inputs)

This repository consumes:

-   **GitHub Actions:** It is built on top of standard GitHub Actions like `actions/checkout` and `actions/setup-python`.
-   **Python Tooling:** The workflows install and use various Python tools, including `pip`, `setuptools`, `pytest`, `pytest-cov`, `PyYAML`, `wheel`, and `stdeb`.
-   **Other Repositories:** The composite action clones and uses the `colcon/publish-python` repository to test the package publishing process.
-   **Configuration from other repos:** The composite action is designed to read a `publish-python.yaml` file from the repository that is calling it, to know how to simulate the publishing step.

## 4. Production (Outputs)

This repository's "product" is its set of reusable GitHub Actions workflows. It does not produce a software package, a binary, or a web application. Its output is consumed by other repositories' CI/CD pipelines.

## 5. CI/CD Pipeline Analysis

This repository is, itself, a CI/CD pipeline. It also has a workflow to test its own functionality:

-   **Workflow File:** `.github/workflows/ci.yaml`
-   **Triggers:** The workflow is triggered on `push` to the `main` branch and on `pull_request`.
-   **Pipeline Stages:** The `ci.yaml` workflow is a "self-test" mechanism. It calls its own `pytest.yaml` reusable workflow to ensure that the CI infrastructure is functioning correctly. This is a good practice for maintaining shared CI infrastructure.

The core of the CI logic, which is used by other repositories, is in `action.yaml`. This composite action includes the following stages:
1.  Initialize a Python virtual environment.
2.  Install the package under test.
3.  Install dependencies using the shared `constraints.txt` files.
4.  Run `pytest` with coverage reporting.
5.  If a `publish-python.yaml` file exists in the calling repository, simulate the package publishing process using the `colcon/publish-python` tool.

## 6. Standalone Usage Guide

This repository is not intended to be used standalone. Its purpose is to be used by other `colcon` repositories within their GitHub Actions workflows.

A typical `colcon` package would use this repository's CI infrastructure by creating a `.github/workflows/ci.yaml` file with the following content:

```yaml
name: Run tests

on:
  push:
    branches: ['master']
  pull_request:

jobs:
  pytest:
    uses: colcon/ci/.github/workflows/pytest.yaml@main
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

This simple workflow delegates the entire testing process to the `colcon/ci` repository, ensuring that the package is tested in a consistent and standardized way.
