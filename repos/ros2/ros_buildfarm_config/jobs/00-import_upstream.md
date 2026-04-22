# `import_upstream` Job

## 1. Job Purpose

The `import_upstream` job is a maintenance task responsible for synchronizing upstream (external) Debian packages into the buildfarm's internal Apt repositories. Its primary function is to ensure that all necessary non-ROS dependencies are available in the local repositories (`building`, `testing`, `main`) before ROS packages are built against them.

This job does not build any ROS packages itself but is a critical prerequisite for the `release-build` pipeline. It runs directly on a dedicated Jenkins agent, **not** in a Docker container.

## 2. Defining Files

-   **Generating Script:** `ros-infrastructure/ros_buildfarm/ros_buildfarm/scripts/release/generate_release_maintenance_jobs.py`
-   **Template File:** `ros-infrastructure/ros_buildfarm/ros_buildfarm/templates/release/deb/import_upstream_job.xml.em`

## 3. Configuration Parameters

The job's behavior is controlled by parameters defined within the Jenkins job itself. These parameters are not typically sourced from the `ros_buildfarm_config` YAML files but are set with defaults in the template.

| Parameter             | Type    | Default Value                                   | Description                                                                                                                              |
| --------------------- | ------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `config_file`         | String  | `/home/jenkins-agent/reprepro_config/ros_bootstrap.yaml` | The path on the agent to a YAML file defining the upstream sources for the `reprepro-updater` tool.                                     |
| `EXECUTE_IMPORT`      | Boolean | `false`                                         | If `false`, the job performs a dry run. If `true`, it commits the changes to the repositories.                                           |
| `IMPORT_TO_MAIN`      | Boolean | `true`                                          | If `true`, packages will be imported into the `main` repository.                                                                         |
| `IMPORT_TO_TESTING`   | Boolean | `true`                                          | If `true`, packages will be imported into the `testing` repository.                                                                      |
| `IMPORT_TO_BUILDING`  | Boolean | `true`                                          | If `true`, packages will be imported into the `building` repository.                                                                     |

## 4. Execution Steps

The job executes a single shell script with the following sequence:

1.  **SCM Checkout:** The Jenkins job first checks out the `reprepro-updater` tool from its [GitHub repository](https://github.com/ros-infrastructure/reprepro-updater).

2.  **Set Commit Flag:** The script checks the value of the `EXECUTE_IMPORT` parameter. If it is `true`, it prepares a `--commit` flag to be passed to the import script. Otherwise, the import script will run in "dry run" mode.

3.  **Set `PYTHONPATH`:** The script adds the checked-out `reprepro-updater/src` directory to the `PYTHONPATH` to make its modules available for execution.

4.  **Execute Import:** The core of the job is the execution of the `import_upstream.py` script from the `reprepro-updater` tool. This script is called conditionally for each of the `building`, `testing`, and `main` repositories, depending on whether the corresponding `IMPORT_TO_*` parameter is `true`. Each call to the script performs the actual synchronization of packages from upstream sources into the specified local buildfarm repository.

## 5. Interacting Resources

-   **Jenkins Agent:** Runs on a dedicated agent with the label `building_repository`.
-   **GitHub:** Checks out the `reprepro-updater` source code.
-   **`reprepro` Apt Repositories:** The job's primary function is to modify the state of the internal `reprepro`-managed repositories on the Jenkins agent.
-   **Upstream Apt Repositories:** The `import_upstream.py` script, as configured by its YAML file, connects to external, upstream Debian repositories to fetch packages.
