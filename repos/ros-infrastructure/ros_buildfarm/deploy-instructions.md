# Deploying a local ROS Buildfarm

This document provides instructions on how to deploy a minimal ROS buildfarm locally using the `ros_buildfarm` package and a custom configuration.

## 1. Prerequisites

Before you can deploy the buildfarm, you need to install the necessary Python packages. It is highly recommended to use a Python virtual environment to avoid conflicts with system packages.

```bash
# Install dependencies for creating a virtual environment
sudo apt update && sudo apt install python3 python3-all python3-pip python3-venv

# Create a directory for the deployment
mkdir -p /tmp/deploy_ros_buildfarm
cd /tmp/deploy_ros_buildfarm

# Create and activate a Python virtual environment
python3 -m venv venv
. venv/bin/activate

# Install the required Python packages
pip3 install empy
pip3 install jenkinsapi
pip3 install rosdistro
pip3 install ros_buildfarm
```

## 2. Jenkins Credentials

The `ros_buildfarm` scripts need credentials to access your Jenkins master. Create a file at `~/.buildfarm/jenkins.ini` with the following content, replacing the URL, username, and password with your own.

```ini
[http://localhost:8080]
username=admin
password=your_jenkins_password_or_api_token
```

**Note:** You can use an API token instead of a plain password. You can generate one from your Jenkins user's configuration page (`http://<your-jenkins-url>/me/configure`).

## 3. Deploying the Configuration

The main script for deploying the buildfarm configuration is `generate_all_jobs.py`. This script takes the URL of your `index.yaml` file as an argument.

To deploy the minimal configuration you have created, run the following command. Make sure to replace `kmom88` with your GitHub username if your fork is located elsewhere.

```bash
# Activate your virtual environment if you haven't already
. /tmp/deploy_ros_buildfarm/venv/bin/activate

# Run the deployment script
generate_all_jobs.py https://raw.githubusercontent.com/KmoM88/ros_buildfarm_config/refs/heads/buildfarm-tests/index.yaml
```

*   The URL should point to the raw `index.yaml` file in your `ros_buildfarm_config` fork on GitHub.
*   The `--commit` flag is necessary to actually apply the changes to your Jenkins instance. Without it, the script will only perform a dry run.

## 4. Post-deployment Initialization

After the script has successfully generated the administrative jobs on your Jenkins instance, you need to trigger a few jobs manually to initialize the buildfarm. Log in to your Jenkins instance and go to the "Manage" view.

1.  **Import Upstream Packages:**
    *   Find the `import_upstream` job and trigger it with the `EXECUTE_IMPORT` parameter checked. This will import the necessary bootstrap packages into your local repository.

2.  **Generate rosdistro Cache:**
    *   Find the `local_rosdistro-cache` job and trigger it. This will generate the cache for the `rosdistro` you have configured.

3.  **Generate Build Jobs:**
    *   Find the `local_reconfigure-jobs` job and trigger it. This will generate the actual CI/build jobs for your configured packages. This step might take a significant amount of time.

After these steps, your local buildfarm should be up and running with a minimal set of CI jobs. You can monitor the progress and results of the builds from your Jenkins dashboard.
