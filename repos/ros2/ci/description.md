# Technical Analysis of ros2/ci

This document provides a deep technical analysis of the `ros2/ci` GitHub repository.

### 1. Repository Discovery & Branching Logic

The `ros2/ci` repository contains the core infrastructure, scripts, and configurations for the official ROS 2 Continuous Integration (CI) build farm. It is a highly specialized repository that underpins the build and test automation for the entire ROS 2 ecosystem.

**Branching Strategy:**

-   **Primary Branch**: The `README.md` refers to `master` as the default branch, which serves as the primary line of development.
-   **Strategy**: Unlike application repositories, `ros2/ci` does not follow a GitFlow or distribution-based branching model. It uses a trunk-based development model where `master` holds the current state of the CI configuration. Other branches are temporary, used for developing features or bug fixes before being merged into `master`. A special `configuration` branch exists to hold Jenkins agent setup information.

### 2. Core Purpose & Architecture

**Core Purpose:**

The repository's technical purpose is to programmatically define and manage the Jenkins CI pipeline for ROS 2. It solves the problem of maintaining a large, complex, and multi-platform build farm by treating the CI **configuration as code**. Instead of manual job configuration in the Jenkins UI, this repository provides the tools to generate and deploy job configurations automatically, ensuring consistency, version control, and reproducibility for the entire CI process.

**High-Level Architecture:**

The system is a bespoke "Configuration as Code" framework centered around Jenkins and Docker.

1.  **Job Generation Script (`create_jenkins_job.py`)**: This Python script is the heart of the system. It connects to a Jenkins master via the `jenkinsapi` library and is responsible for creating or updating CI jobs.
2.  **Job Templates (`job_templates/*.xml.em`)**: The repository contains Jenkins `config.xml` files written as templates using the `empy` templating engine. The `create_jenkins_job.py` script populates these templates with specific parameters (e.g., repository URLs, target platforms) to generate the final XML configuration for each Jenkins job.
3.  **Dockerized Build Environments (`linux_docker_resources/`)**: The actual CI jobs run inside Docker containers. This directory contains `Dockerfile`s that define the build environments for various platforms (e.g., Ubuntu, RHEL). These Dockerfiles install all necessary system dependencies, compilers, and tools, creating a clean and reproducible environment for every build.
4.  **Batch Job Execution (`run_ros2_batch.py`)**: This script is the main entry point executed *inside* a Jenkins job. It is responsible for orchestrating the actual CI tasks: checking out code, running the build (`colcon build`), executing tests, and collecting results.

### 3. Consumption (Inputs)

The system consumes several types of inputs to function:

-   **Jenkins Instance**: It requires a running Jenkins master and build agents on Linux, Windows, and macOS.
-   **Python Dependencies**: `create_jenkins_job.py` depends on Python libraries like `empy`, `jenkinsapi`, and `ros_buildfarm`.
-   **Proprietary Middleware (Git Submodules)**: The `.gitmodules` file defines dependencies on private `osrf` repositories containing the licensed binaries for RTI Connext DDS, a commercial middleware implementation used for testing. These are pulled in as git submodules during the Docker image build process.
-   **ROS 2 Source Code**: The CI jobs orchestrated by this repository consume the source code of the various ROS 2 repositories as their primary input to be built and tested.

### 4. Production (Outputs)

This repository's primary output is a fully configured Jenkins build farm. The tangible outputs from the jobs it creates include:

-   **Jenkins Job Configurations**: The main product is the set of jobs created on the Jenkins master.
-   **Build & Test Artifacts**: The executed jobs produce build artifacts (compiled code), test logs, code coverage reports, and other metrics.
-   **Packaged Binaries**: The `packaging_job.xml.em` template indicates that this system is also used to generate and release official Debian packages for ROS 2 distributions.
-   **Docker Images**: The `Dockerfile`s are used to build and likely push CI environment images to a Docker registry.

### 5. CI/CD Pipeline Analysis

This repository is unique in that it **defines the CI system itself**.

-   **Jenkins**: The entire infrastructure is built for Jenkins. No `Jenkinsfile` is present because the repository *creates* the Jenkins jobs, rather than being triggered by one. The logic is in the Python and shell scripts.
-   **GitHub Actions**: No GitHub Actions workflows were found in the repository. The testing and validation of this tooling are likely performed on the Jenkins farm it configures, in a self-hosting or "dogfooding" model.

### 6. Standalone Usage Guide

Running this system "standalone" means replicating a piece of the ROS 2 CI pipeline locally. The `README.md` provides the primary guide for configuring a new Jenkins instance. A developer might also use the components to debug a CI failure.

**Guide to Running a Batch Job Locally (Conceptual):**

1.  **Build the CI Docker Image**: A developer would first need to build one of the CI Docker images locally.
    ```bash
    # From the ros2/ci repository root
    cd linux_docker_resources
    # This requires access to the private submodule repositories
    docker build -t ros2-ci:latest .
    ```

2.  **Run the Docker Container**: Start the container, mounting the ROS 2 source code to be tested.
    ```bash
    # Check out ROS 2 source into ~/ros2_ws/src
    docker run -it --rm -v ~/ros2_ws:/ws ros2-ci:latest
    ```

3.  **Execute the Batch Script**: Inside the container, run the `run_ros2_batch.py` script, which mimics what Jenkins does. This script would check out, build, and test the code within the `/ws` directory.
    ```bash
    # Inside the container
    /path/to/run_ros2_batch.py --workspace /ws
    ```
This provides a way to reproduce the CI environment and process without needing a full Jenkins farm.