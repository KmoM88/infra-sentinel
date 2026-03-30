# `osrf/createrepo-agent`

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `main`. There is also a branch named `cottsay/repo-touch`, which appears to be a feature branch. The branching strategy appears to be simple, with `main` as the primary line of development.

## 2. Core Purpose & Architecture

The repository contains `createrepo-agent`, a tool designed to rapidly and repeatedly generate RPM repository metadata. It is built primarily in C, with Python bindings available. The core architecture leverages the Assuan Inter-Process Communication (IPC) protocol to create a daemon process. This daemon caches metadata for clusters of associated RPM sub-repositories, which avoids the need to reload and parse the metadata each time a change is made. This design is inspired by `gpg-agent`, from which the project derives its name.

The project uses `scikit-build-core` as its build system, which facilitates the integration of the C code as a Python extension.

## 3. Consumption (Inputs)

The project has the following dependencies:

### System-level Libraries (as seen in `ci.yaml` and `pyproject.toml`):
- `cmake`
- `libassuan-dev`
- `libcreaterepo-c-dev`
- `libgpg-error-dev`
- `libgpgme-dev`
- `libgtest-dev` (for testing)
- `make`
- `valgrind` (for memory checking)

### Python Dependencies (from `pyproject.toml`):
- `scikit-build-core` (build backend)
- `pytest` (for testing)

### CMake `find_package` Dependencies (from `CMakeLists.txt`):
- `createrepo_c` (version 0.13.0 or greater)
- `glib-2.0`
- `gpg-error` (version 1.13 or greater)
- `gpgme` (version 1.7.0 or greater)
- `assuan` (version 2.2.0 or greater)

## 4. Production (Outputs)

This repository produces:

- A standalone binary executable named `createrepo-agent`.
- Python wheels (`.whl` files) for distribution on PyPI. These wheels include the compiled C extension, allowing the agent to be used as a Python library.

## 5. CI/CD Pipeline Analysis

The CI/CD pipeline is managed through GitHub Actions, defined in the `.github/workflows/` directory.

### `ci.yaml`
- **Triggers**: Pushes to `main` and `devel` branches, and on pull requests.
- **Jobs**:
  - `build_and_test`: This job runs on Ubuntu 22.04 and 24.04. It installs the necessary system-level dependencies, builds the C code using `cmake`, runs tests using `ctest` (including memory checks with `valgrind`), and uploads coverage information to Codecov.
  - `yamllint`: This job ensures that all YAML files in the repository adhere to the project's style guidelines.

### `python.yaml`
- **Triggers**: On pull requests that modify Python packaging files (`.github/workflows/python.yaml`, `pyproject.toml`), on the creation of new tags, and can be triggered manually (`workflow_dispatch`).
- **Jobs**:
  - `sdist`: This job builds the source distribution (`.tar.gz`) of the Python package.
  - `wheel`: This job builds the Python wheels for both `x86_64` and `aarch64` architectures on Ubuntu 24.04 using `cibuildwheel`.

There is no evidence of a `Jenkinsfile` in the repository, indicating that Jenkins is not used for CI/CD.

## 6. Standalone Usage Guide

To build and run the `createrepo-agent` locally, a developer would follow these steps, based on the `ci.yaml` workflow:

1.  **Install dependencies** (on a Debian-based system):
    ```bash
    sudo apt update && sudo apt install -y 
        cmake 
        libassuan-dev 
        libcreaterepo-c-dev 
        libgpg-error-dev 
        libgpgme-dev 
        libgtest-dev 
        make
    ```

2.  **Clone the repository**:
    ```bash
    git clone https://github.com/osrf/createrepo-agent.git
    cd createrepo-agent
    ```

3.  **Build the project**:
    ```bash
    mkdir build
    cd build
    cmake ..
    make
    ```

4.  **Run the tests**:
    ```bash
    ctest --output-on-failure
    ```
