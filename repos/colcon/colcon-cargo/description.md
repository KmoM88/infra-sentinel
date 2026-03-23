# Technical Analysis of colcon/colcon-cargo

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `main`. The branching strategy is simple, with the `main` branch being protected and feature development happening in other, short-lived branches. There is no evidence of a complex branching model like GitFlow.

## 2. Core Purpose & Architecture

`colcon-cargo` is an extension for `colcon-core` that adds support for building, testing, and discovering Rust packages managed by `cargo`. Its architecture is a clear example of `colcon`'s plugin system. It uses entry points to register itself with `colcon-core` and provide implementations for various extension points, including:
-   `package_augmentation`
-   `package_discovery`
-   `package_identification`
-   `task.build`
-   `task.test`

This allows `colcon` to recognize and handle `Cargo.toml` files, treating Rust packages as first-class citizens within a `colcon` workspace alongside packages of other types (e.g., Python, C++).

## 3. Consumption (Inputs)

The repository's dependencies are:

-   **External Libraries/Frameworks:**
    -   `colcon-core>=0.19.0`: The core framework that this package extends.
    -   `tomli`: Used for parsing `Cargo.toml` files.
-   **External Toolchain:** The Rust `cargo` toolchain must be installed and available in the system's `PATH` for this extension to function.
-   **Other Repositories or Submodules:** The CI pipeline references `colcon/ci` for a reusable testing workflow.

## 4. Production (Outputs)

This repository produces a Python package, which is published to PyPI (Python Package Index). This package provides the `colcon-cargo` extension to be used by `colcon-core`. It does not produce a standalone binary or a web application.

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for its CI/CD pipeline.

-   **Workflow File:** `.github/workflows/ci.yaml`
-   **Triggers:** The workflow is triggered on `push` events to the `main` branch and on any `pull_request`.
-   **Pipeline Stages:** The `ci.yaml` file defines a single job, `pytest`, which uses a reusable workflow from another repository: `colcon/ci/.github/workflows/pytest.yaml@main`. This indicates a standardized CI setup across the `colcon` organization. The job uses a `CODECOV_TOKEN` secret, which implies that it runs tests and uploads code coverage reports to Codecov.

## 6. Standalone Usage Guide

To use this extension, a developer needs to have `colcon-core` and the Rust `cargo` toolchain installed.

1.  **Install the extension:**
    ```bash
    pip install colcon-cargo
    ```

2.  **Create a workspace with Rust packages:**
    ```bash
    mkdir -p my_workspace/src
    cd my_workspace/src
    cargo new --lib my_rust_pkg
    cd ..
    ```

3.  **Build the workspace:**
    `colcon` will automatically discover the Rust package via the `colcon-cargo` extension and use `cargo` to build it.
    ```bash
    colcon build
    ```

4.  **Test the workspace:**
    Similarly, `colcon` will use `cargo test` to run the tests for the Rust package.
    ```bash
    colcon test
    ```
