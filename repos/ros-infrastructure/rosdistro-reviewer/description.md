# Technical Analysis of ros-infrastructure/rosdistro-reviewer

## 1. Repository Discovery & Branching Logic

The primary branch for this repository is `main`. The development model appears to be a standard feature-branch workflow, where changes are proposed via pull requests to the `main` branch.

## 2. Core Purpose & Architecture

`rosdistro-reviewer` is a specialized tool designed to automate the validation and review of changes to the `rosdistro` index and the `rosdep` database. These are critical, manually-curated files in the ROS ecosystem, and this tool helps maintain their integrity by checking for common errors and enforcing conventions.

The architecture is a Python-based command-line application that can also function as a composite GitHub Action. It has a plugin-based architecture, evidenced by the entry points in `setup.cfg`. This allows for extensibility:
-   **Element Analyzers:** Different modules can be plugged in to analyze specific types of file changes (e.g., `rosdep` key changes, `yamllint` for file syntax).
-   **Submitters:** The results of the analysis can be submitted to different platforms. The primary submitter is for posting reviews to GitHub Pull Requests.

## 3. Consumption (Inputs)

The tool has the following dependencies, as defined in `setup.cfg`:

-   **Python Libraries:**
    -   `colcon-core`
    -   `GitPython` (for interacting with git repositories)
    -   `rosdep`
    -   `unidiff` (for parsing git diffs)
    -   `PyYAML`
    -   `yamllint`
    -   `PyGithub` (for the optional `github` functionality)
-   **Other Repositories:** The CI pipeline references `ros-infrastructure/ci` for a reusable `pytest` workflow.

## 4. Production (Outputs)

This repository produces two main outputs:
1.  A **Python package** published to PyPI, which provides a command-line tool named `rosdistro-reviewer`.
2.  A **reusable composite GitHub Action**, defined in `action.yml`, which wraps the command-line tool for easy use in CI/CD pipelines.

## 5. CI/CD Pipeline Analysis

The repository uses GitHub Actions for its CI/CD pipeline. The main workflow is defined in `.github/workflows/ci.yaml` and is triggered on `push` to `main` and on `pull_request`. It consists of four distinct jobs:

1.  **`pytest`:** This job uses a reusable workflow from `ros-infrastructure/ci` to run the Python test suite with `pytest` and upload coverage reports to Codecov.
2.  **`sphinx_documentation`:** This job builds the project's Sphinx documentation and checks for warnings.
3.  **`yamllint`:** A linting job that checks all YAML files in the repository for style and syntax errors.
4.  **`deploy_documentation`:** This job is triggered only on pushes to the `main` branch. It takes the documentation artifact built by the `sphinx_documentation` job and deploys it to GitHub Pages.

## 6. Standalone Usage Guide

### Local Usage
A developer can use this tool locally to validate their changes before creating a pull request.

1.  **Install the tool:**
    ```bash
    pip install rosdistro-reviewer
    ```
2.  **Run the reviewer:**
    Navigate to your local git repository of `rosdistro` or `rosdep` and run the command. By default, it reviews uncommitted changes.
    ```bash
    # Review uncommitted changes
    rosdistro-reviewer

    # Review changes on the current branch against the master branch
    rosdistro-reviewer --target-ref origin/master
    ```

### GitHub Actions Usage
This tool is designed to be used in a GitHub Actions workflow to automatically review pull requests. A repository like `ros/rosdistro` would have a workflow that uses this action.

1.  Create a workflow file (e.g., `.github/workflows/reviewer.yaml`).
2.  Add a job that uses the `rosdistro-reviewer` action:

    ```yaml
    name: Rosdistro Review

    on:
      pull_request_target:
        types: [opened, synchronize]

    jobs:
      review:
        runs-on: ubuntu-latest
        steps:
          - uses: ros-infrastructure/rosdistro-reviewer@main
            with:
              token: ${{ secrets.GITHUB_TOKEN }}
    ```
This job would then automatically post a review on any pull request that is opened or updated.
