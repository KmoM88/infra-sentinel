# Technical Analysis of osrf/buildfarm-tools

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `main` (protected).
- **Branching Strategy:** The repository follows a standard feature-branch workflow. Developers create branches for new features or fixes and open pull requests to merge them into the `main` branch.

## 2. Core Purpose & Architecture

- **Technical Purpose:** This repository provides a collection of tools for querying, analyzing, and triaging data from the ROS (Robot Operating System) and Gazebo buildfarms. It is used by the "buildfarmer" team to maintain the continuous integration (CI) systems for these projects and by developers to diagnose CI failures.
- **High-Level Architecture:** The repository consists of a set of Python and Ruby scripts that interact with the Jenkins API of the buildfarms. The data is collected and stored in a local SQLite database (`buildfarmer.db`). The architecture is script-based, with a focus on data aggregation and reporting.

## 3. Consumption (Inputs)

- **External Libraries/Frameworks:**
  - **Python:** The `requirements.txt` file lists the following dependencies:
    - `python-jenkins`: To interact with the Jenkins API.
    - `pyyaml`: For parsing YAML files.
    - `urllib3`: A dependency of `python-jenkins`.
  - **Ruby:** The repository contains Ruby scripts (e.g., `check_buildfarm.rb`) and requires a Ruby installation.
- **Other Repositories or Submodules:** No submodules are referenced.
- **Required APIs or External Services:**
  - **Jenkins API:** The tools heavily rely on the Jenkins APIs of the ROS and Gazebo buildfarms to fetch build data. The buildfarms are located at:
    - `build.ros.org`
    - `build.ros2.org`
    - `build.osrfoundation.org`
    - `ci.ros2.org`

## 4. Production (Outputs)

- **Packages/Binaries:** The repository does not produce any packages (NPM, PyPI) or compiled binaries.
- **Deployments:** The primary output is a set of reports and data analysis. The `.github/workflows/greenness-reports-deploy.yml` GitHub Actions workflow suggests that these reports are deployed as a static website, likely to GitHub Pages.

## 5. CI/CD Pipeline Analysis

- **GitHub Actions:** The repository uses GitHub Actions for its CI/CD pipeline. The workflows are defined in the `.github/workflows/` directory:
  - `daily-workflow-ci.yml`: A workflow that likely runs daily to perform CI checks on the tooling itself.
  - `dailyWorkflow.yml`: This is the main workflow that runs on a schedule (daily). It appears to be responsible for gathering data from the buildfarms and updating the local database.
  - `greenness-reports-deploy.yml`: This workflow is triggered on pushes to the `main` branch and deploys the generated reports to a website.

## 6. Standalone Usage Guide

Here is a brief "Quick Start" guide to run the tools locally:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/osrf/buildfarm-tools.git
    cd buildfarm-tools
    ```
2.  **Install dependencies:**
    - Install [Ruby](https://www.ruby-lang.org/en/documentation/installation/).
    - Install Python dependencies:
      ```bash
      python3 -m pip install -r requirements.txt
      ```
3.  **Run a test script:**
    You can test your installation by running a script to check the status of the buildfarms:
    ```bash
    cd database/scripts
    ./check_buildfarm.rb
    ```
    This script will take about a minute to run and will report any ongoing issues on the buildfarms.
