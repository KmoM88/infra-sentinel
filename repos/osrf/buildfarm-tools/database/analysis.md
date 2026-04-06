# Technical Analysis of `osrf/buildfarm-tools/database/`

## 1. High-Level Overview

The `database/` directory is the core component of the `osrf/buildfarm-tools` repository. It embodies a data-centric architecture where a central SQLite database, `buildfarmer.db`, serves as the single source of truth for all buildfarm monitoring and analysis activities. This directory contains the database itself, the SQL schema definitions, and a comprehensive suite of scripts (written in Ruby, Python, Shell, and SQL) for populating, querying, and maintaining the data.

The primary responsibility of this component is to provide a structured, persistent storage layer for historical build data from the ROS and Gazebo Jenkins buildfarms. By consolidating this data, it enables powerful querying and trend analysis, which is essential for identifying, tracking, and resolving build regressions, flaky tests, and other CI/CD issues.

---

## 2. Granular Breakdown

### a. The Database (`buildfarmer.db`)

This is a standard SQLite database file. It contains all the historical data and is the central artifact of this directory. Its presence indicates that the system is designed for local or file-based data analysis, rather than a client-server database model.

### b. Database Schema (`sql/` directory)

The schema is defined by a series of `CREATE TABLE` SQL scripts. The key tables include:

- **`build_status`**: The main fact table, capturing the status (`SUCCESS`, `FAILURE`, etc.), duration, and test results for every build of every job.
- **`build_failures` & `test_failures`**: These tables store details about specific build and test failures, providing a granular view of what went wrong.
- **`test_fail_issues`**: A dimension table that links recurring test failures (`error_name`) to external GitHub issue URLs. This is crucial for tracking known issues and preventing duplicate triage efforts. It maintains the status of the issue (e.g., `OPEN`, `COMPLETED`, `INVESTIGATING`).
- **`build_regression_reasons`**: Stores a catalog of known patterns that indicate specific reasons for build failures, allowing for automated classification of new regressions.
- **`server_status` & `last_time_updated`**: These tables store metadata about the build infrastructure and the data refresh process itself.

### c. Scripts (`scripts/` directory)

This directory contains a rich ecosystem of scripts forming a layered architecture for database interaction.

- **Layer 1: SQL Queries (`*.sql`)**: These are raw, parameterized SQL scripts that perform specific queries. They are not meant to be executed directly but are called by wrapper scripts.
    - *Examples:* `builds_failing_today.sql`, `get_active_known_issues.sql`, `calculate_flakiness_jobs.sql`.

- **Layer 2: Shell Wrappers (`*.sh`)**: These are simple Bash scripts that provide a command-line interface to the SQL queries.
    - **`sql_run.sh`**: This is a key utility. It's a generic wrapper that takes an SQL file and optional parameters, replaces the `@paramN@` placeholders in the SQL, and executes it against `buildfarmer.db` using the `sqlite3` CLI.
    - *Other Examples:* `issue_save_new.sh` and `close_old_known_issues.sh` are higher-level wrappers that use `sql_run.sh` to modify the `test_fail_issues` table.

- **Layer 3: Business Logic (Ruby `*.rb` & Python `*.py`)**: These scripts contain the most complex logic. They orchestrate calls to the lower-level shell and SQL scripts to perform advanced analysis and generate reports.
    - **`check_buildfarm.rb`**: A primary entry point for daily analysis. It queries for test regressions, calculates flakiness statistics by calling other scripts, enriches the data with known issue information, and prints a human-readable report to the console.
    - **`generate_report.rb`**: This script produces a structured JSON report by querying for various types of regressions (build, consecutive test failures, flaky tests) and maintenance issues. This JSON output is likely consumed by downstream automation or dashboards.

---

## 3. Usage & Implementation

The components in this directory are designed to be used from a command-line environment, either manually by a buildfarmer or automatically as part of a CI/CD workflow.

### Example 1: Running a Simple SQL Query

A developer can use `sql_run.sh` to directly query the database.

```bash
# Find all Jenkins jobs that have never had a successful build
./database/scripts/sql_run.sh ./database/scripts/jobs_never_passed.sql
```

### Example 2: Checking for Regressions with Parameters

The scripts can be parameterized for more specific queries.

```bash
# Check the history for a specific test failure in a specific job
# The 'error_appearances_in_job.sql' script expects two parameters.
./database/scripts/sql_run.sh ./database/scripts/error_appearances_in_job.sql "my_failing_test_name" "my_jenkins_job_name"
```

### Example 3: Generating a Daily Report

The Ruby scripts provide a high-level, abstracted way to get a full status overview.

```bash
# Generate a summary of all current buildfarm issues, excluding any jobs
# with "performance" in the name.
./database/scripts/check_buildfarm.rb --exclude "performance"
```
This will produce a formatted text output summarizing flaky tests and other regressions.

---

## 4. Technical Nuances

- **Dependencies:**
    - **`sqlite3` CLI:** Essential for all database operations. The `sql_run.sh` script directly depends on it.
    - **Ruby & Python Runtimes:** Required to execute the higher-level business logic scripts.
    - **`bash`:** The wrapper scripts are written in Bash and may use features not present in other shells.
- **Data Flow & State:** The entire system is stateful, with the state being managed in the `buildfarmer.db` file. The daily CI jobs run scripts that fetch the latest data from Jenkins, update the tables in the database, and then run analysis on that updated state.
- **Performance Considerations:**
    - By using a local SQLite database, the system avoids network latency for complex queries, making analysis very fast.
    - The database is a single file, which can be a bottleneck if concurrent writes are needed. However, the workflow appears to be single-threaded (a daily job that updates the DB), so this is not a major issue.
    - The use of raw SQL and efficient scripting languages (Ruby, Python) ensures that data processing is performant, even with a large database.
- **Design Pattern - Command Query Responsibility Segregation (CQRS) at a Script Level:** The system exhibits a separation of concerns. There are scripts dedicated to writing/updating data (e.g., fetching from Jenkins and inserting into `build_status`), and a separate, larger set of scripts dedicated to reading/querying that data for analysis and reporting.
