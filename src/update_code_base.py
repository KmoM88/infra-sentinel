import os
import subprocess
import yaml

# ANSI color codes
COLOR_RED = "\033[91m"
COLOR_GREEN = "\033[92m"
COLOR_YELLOW = "\033[93m"
COLOR_RESET = "\033[0m"

def sync_repositories(config_file='repos.yaml'):
    """
    Clones or updates Git repositories using SSH, based on a YAML configuration file.

    The script reads the configuration, and for each repository:
    - If the local directory already exists, it changes the remote to SSH (if necessary) and runs 'git pull'.
    - If it does not exist, it clones the repository from GitHub using SSH.
    """
    # Check if the configuration file exists
    if not os.path.exists(config_file):
        print(f"{COLOR_RED}Error: Configuration file '{config_file}' not found.{COLOR_RESET}")
        return

    # Read the YAML file
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)

    base_path = config.get('base_path')
    repositories = config.get('repos', [])

    # Validate that base_path is a valid directory
    if not base_path or not os.path.isdir(base_path):
        print(f"{COLOR_RED}Error: The base path '{base_path}' is not a valid directory or does not exist.{COLOR_RESET}")
        return

    print(f"Starting synchronization with SSH in the base directory: {base_path}")
    print("=" * 60)

    for repo_full_name in repositories:
        try:
            # Split organization and repository name
            organization, repo_name = repo_full_name.split('/')
        except ValueError:
            print(f"{COLOR_YELLOW}WARNING: Skipping entry with invalid format: '{repo_full_name}'.{COLOR_RESET}")
            continue

        # Build the SSH URL for the repository and the local path
        repo_url = f"git@github.com:{organization}/{repo_name}.git"
        org_path = os.path.join(base_path, organization)
        repo_path = os.path.join(org_path, repo_name)

        print(f"Processing: {repo_full_name}")

        # Check if the repository directory already exists
        if os.path.isdir(repo_path):
            print(f"Repository already exists. Verifying and updating in '{repo_path}'...")
            try:
                # Check the current remote URL
                current_remote_result = subprocess.run(
                    ['git', 'remote', 'get-url', 'origin'],
                    cwd=repo_path, check=True, capture_output=True, text=True
                )
                current_remote_url = current_remote_result.stdout.strip()

                # If the URL is not SSH, change it
                if not current_remote_url.startswith("git@"):
                    print(f"-> Changing remote URL to SSH: {repo_url}")
                    subprocess.run(
                        ['git', 'remote', 'set-url', 'origin', repo_url],
                        cwd=repo_path, check=True
                    )

                # Run 'git pull' to update
                print("-> Updating with 'git pull'...")
                subprocess.run(
                    ['git', 'pull'],
                    cwd=repo_path, check=True, capture_output=True, text=True
                )
                print(f"{COLOR_GREEN}-> Update completed successfully.{COLOR_RESET}")
            except subprocess.CalledProcessError as e:
                print(f"{COLOR_RED}-> ERROR updating repository '{repo_path}':{COLOR_RESET}")
                print(f"{COLOR_RED}{e.stderr}{COLOR_RESET}")
        else:
            # If it does not exist, clone the repository using SSH
            print(f"Repository does not exist. Cloning from '{repo_url}'...")
            os.makedirs(org_path, exist_ok=True)
            try:
                subprocess.run(
                    ['git', 'clone', repo_url, repo_path],
                    check=True, capture_output=True, text=True
                )
                print(f"{COLOR_GREEN}-> Repository cloned successfully in '{repo_path}'.{COLOR_RESET}")
            except subprocess.CalledProcessError as e:
                print(f"{COLOR_RED}-> ERROR cloning '{repo_url}':{COLOR_RESET}")
                print(f"{COLOR_RED}{e.stderr}{COLOR_RESET}")
        
        print("-" * 60)

if __name__ == "__main__":
    sync_repositories('repos.yaml')
