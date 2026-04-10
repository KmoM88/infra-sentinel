# `colcon/colcon-notification` Technical Analysis

## 1. Repository Discovery & Branching Logic

- **Primary Branch:** `master`
- **Branching Strategy:** The repository has only one branch, `master`. All development happens on this branch.

## 2. Core Purpose & Architecture

`colcon-notification` is an extension for `colcon-core` that provides desktop notifications and other status updates. It hooks into `colcon`'s event system to monitor the progress of a command and sends a summary notification when the command is finished.

The architecture is based on `colcon-core`'s plugin system:

- **Event Handlers:** The package provides several event handler extensions that listen for events from `colcon-core` and provide feedback to the user.
  - `desktop_notification`: Sends a desktop notification when a `colcon` command finishes.
  - `status`: Displays a status message in the terminal.
  - `terminal_title`: Updates the terminal title with the current status.
- **Desktop Notification Extensions:** The package defines a new extension point, `colcon_notification.desktop_notification`, for different ways of sending desktop notifications. It also provides implementations for Linux, macOS, and Windows.

## 3. Consumption (Inputs)

- **External Libraries/Frameworks:** The dependencies are listed in `setup.cfg`:
  - `colcon-core>=0.3.7`
  - `notify2` (on Linux)
  - `pywin32` (on Windows)
- **Other Repositories:** The CI/CD pipeline references the `colcon/ci` repository for shared workflows.
- **APIs or External Services:** No external APIs are required.

## 4. Production (Outputs)

- **PyPI Package:** The repository is set up to be packaged and distributed on PyPI as `colcon-notification`.
- **Debian Package:** The `setup.py` and `stdeb.cfg` files indicate that it can also be built as a Debian package.
- **Application Bundle:** It includes a macOS application bundle (`colcon_terminal_notifier.app`) which is used to send notifications on macOS.

## 5. CI/CD Pipeline Analysis

The CI/CD pipeline is defined in `.github/workflows/ci.yaml`.

- **Triggers:** The workflow runs on pushes to the `master` branch and on pull requests.
- **Jobs:** It has a single job, `pytest`, which reuses a workflow from the `colcon/ci` repository. This job runs tests with `pytest` and uploads code coverage reports to Codecov.

## 6. Standalone Usage Guide

To use `colcon-notification`, you need to have `colcon-core` installed.

1.  **Install `colcon-core`:**
    ```bash
    pip install colcon-core
    ```

2.  **Install `colcon-notification`:**
    ```bash
    pip install colcon-notification
    ```

3.  **Run a `colcon` command:** The notification extension will be automatically activated.
    ```bash
    colcon build
    ```
    When the command finishes, you should see a desktop notification.

## 7. Execution Flow Walkthrough

`colcon-notification` works by plugging into the event system of `colcon-core`. Here's a walkthrough of how the desktop notification event handler works:

1.  **Extension Discovery:** When `colcon` starts, it discovers all available extensions, including the event handlers from `colcon-notification`. The `DesktopNotificationEventHandler` is registered as an event handler for the `colcon_core.event_handler` extension point.

2.  **Event Handling:** The `DesktopNotificationEventHandler` is instantiated and its `__call__` method is invoked by the event reactor for every event.

3.  **State Accumulation:** The event handler doesn't send a notification for every event. Instead, it accumulates state as it receives events:
    - It remembers if there was any output to `stderr`.
    - It remembers if there were any test failures.
    - It keeps a list of failed jobs.

4.  **Shutdown Event:** When the `colcon` command is about to exit, the event reactor sends an `EventReactorShutdown` event.

5.  **Sending Notification:** When the `DesktopNotificationEventHandler` receives the `EventReactorShutdown` event, it sends a single notification that summarizes the outcome of the command:
    - If there were failed jobs, it sends a "failure" or "aborted" notification.
    - If there were no failed jobs, but there was `stderr` output or test failures, it sends a "warning" notification.
    - If there were no failures or warnings, it sends a "success" notification.

6.  **Platform-Specific Notification:** The `DesktopNotificationEventHandler` calls the `notify()` function, which in turn uses the `colcon_notification.desktop_notification` extension point to find an appropriate implementation for the current operating system (e.g., `notify-send` on Linux, `terminal-notifier` on macOS, or the Windows API on Windows).
