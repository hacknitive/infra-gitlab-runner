<p align="center">
  <img src="./assets/avatar.jpeg" alt="GitLab Runner Logo" width="200">
</p>

<h1 align="center">Automated GitLab Runner with Docker Compose</h1>

<p align="center">
  <a href="https://github.com/hacknitive/infra-gitlab-runner/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://hub.docker.com/r/gitlab/gitlab-runner/">
    <img src="https://img.shields.io/badge/Docker-GitLab%20Runner-blue?logo=docker" alt="Docker Image">
  </a>
</p>

A standardized, flexible, and fully automated solution for deploying GitLab Runners using Docker. This project enforces a strict configuration-as-code approach, enabling you to deploy consistent, production-ready runners in minutes with a single `.env` file.

---

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview \& Features](#overview--features)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Deployment in 4 Steps](#deployment-in-4-steps)
  - [Step 1: Clone the Repository](#step-1-clone-the-repository)
  - [Step 2: Create and Configure the `.env` File](#step-2-create-and-configure-the-env-file)
  - [Step 3: Launch the Runner Service](#step-3-launch-the-runner-service)
  - [Step 4: Register and Configure the Runner](#step-4-register-and-configure-the-runner)
- [Configuration Details (`.env` Variables)](#configuration-details-env-variables)
- [Verification](#verification)
- [Project Structure](#project-structure)
- [Best Practices Implemented](#best-practices-implemented)
- [Contributing](#contributing)
- [License](#license)

---

## Overview & Features

This project automates the entire lifecycle of a GitLab Runner, from initial setup to registration and configuration. It is designed for reliability, consistency, and ease of use across multiple environments (development, staging, production).

-   ✅ **Strict & Explicit Configuration**: All settings are controlled via a single `.env` file. The system will fail with a clear error if any variable is missing, eliminating ambiguity.
-   ✅ **Zero-Touch Registration**: A robust shell script reads your `.env` file and executes a non-interactive registration command, ensuring a repeatable and error-free setup.
-   ✅ **Powerful Docker Executor**: Pre-configured to use the isolated and secure Docker executor, allowing your CI/CD jobs to run in clean, containerized environments.
-   ✅ **Persistent & Stateless**: The runner's configuration (`config.toml`) is stored in a Docker volume on the host, making the runner container itself stateless. It can be stopped, removed, or upgraded without losing its identity.
-   ✅ **Reusable & Environment-Agnostic**: Use the same repository and process to deploy runners on any server. Simply create a new `.env` file for each environment to ensure consistency.
-   ✅ **Comprehensive Logging**: The registration script provides clear, step-by-step output, making troubleshooting simple.

## How It Works

The system is designed with a clear separation of concerns. You define *what* to deploy in the `.env` file, and the tools handle *how* to deploy it.

```
+-------------------+      +------------------------+      +----------------------+
|                   |----->|                        |----->|                      |
|   .env File       |      |   docker-compose.yml   |      |   GitLab Runner      |
| (Your Settings)   |      | (Starts the Service)   |      |   Container (Idle)   |
|                   |<-----|                        |<-----|                      |
+-------------------+      +------------------------+      +----------------------+
        |                                                           |
        |                                                           |
        |   +----------------------+      +----------------------+  |
        +-->|                      |----->|                      |  |
            |  register-runner.sh  |      |   Registers with     |<-+
            | (Automates Setup)    |      |   GitLab Instance    |
            +----------------------+      +----------------------+
```

1.  You copy `.env.example` to `.env` and fill in your specific details (GitLab URL, token, runner tags, etc.).
2.  `docker compose up -d` reads the `.env` file to start the GitLab Runner container service with the correct image and volume mounts.
3.  `./register-runner.sh` reads the same `.env` file and executes the `gitlab-runner register` command inside the running container, connecting it securely to your GitLab instance.
4.  The script finishes by restarting the container to ensure all settings are applied.

## Prerequisites

-   A server (VM or physical) with `sudo` or Docker group access.
-   [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) installed.
-   A GitLab Runner **registration token**.
    -   In GitLab, navigate to your **Project** or **Admin Area**.
    -   Go to **Settings > CI/CD** and expand the **Runners** section.
    -   Click **New project runner** (or equivalent) and copy the token.

## Deployment in 4 Steps

Follow these steps on the server where you want the runner to operate.

### Step 1: Clone the Repository

```bash
git clone https://github.com/hacknitive/infra-gitlab-runner.git
cd infra-gitlab-runner
```

### Step 2: Create and Configure the `.env` File

This is the **only manual configuration step**. Copy the template and edit it with your values.

1.  **Create the `.env` file:**
    ```bash
    cp .env.example .env
    ```

2.  **Edit the `.env` file:**
    Open `.env` in a text editor (like `nano` or `vim`) and provide a value for **every variable**. The scripts will not run without them. See the [Configuration Details](#configuration-details-env-variables) section below for a full explanation of each variable.

### Step 3: Launch the Runner Service

This command starts the GitLab Runner container in the background. It will be running but not yet registered with your GitLab instance.

```bash
docker compose up -d
```

*This command will fail if required variables like `RUNNER_IMAGE_NAME` or `CONTAINER_NAME` are not set in your `.env` file.*

### Step 4: Register and Configure the Runner

This script automates the final setup.

1.  **Make the script executable (only needs to be done once):**
    ```bash
    chmod +x register-runner.sh
    ```

2.  **Run the script:**
    ```bash
    ./register-runner.sh
    ```

The script will register the runner, set the global concurrent job limit, and restart the container. Upon completion, you will see a `🎉 SUCCESS!` message.

Your runner is now fully configured and operational! It is best practice to quickly verify its settings in the GitLab UI to ensure they match your `.env` file.

## Configuration Details (`.env` Variables)

All configuration is handled by these environment variables. **All variables are required.**

| Variable                        | Description                                                                                                                             | Example                                                    |
| :------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------- |
| **GitLab Instance Details**     |                                                                                                                                         |                                                            |
| `GITLAB_URL`                    | The full URL of your GitLab instance.                                                                                                   | `https://gitlab.com`                                       |
| `REGISTRATION_TOKEN`            | The secret registration token from the GitLab UI.                                                                                       | `glrt-xxxxxxxxxxxxxx`                                      |
| **Runner Configuration**        |                                                                                                                                         |                                                            |
| `RUNNER_DESCRIPTION`            | A human-readable description for the runner in the UI.                                                                                  | `Production Runner (Web)`                                  |
| `RUNNER_TAGS`                   | Comma-separated list of tags. Jobs in `.gitlab-ci.yml` use these to select this runner.                                                 | `docker,production,web`                                    |
| `RUNNER_EXECUTOR`               | The executor to use. `docker` is highly recommended.                                                                                    | `docker`                                                   |
| `RUNNER_DEFAULT_DOCKER_IMAGE`   | The default Docker image for jobs if not specified in `.gitlab-ci.yml`.                                                                 | `alpine:latest`                                            |
| **Runner Behavior**             |                                                                                                                                         |                                                            |
| `RUN_UNTAGGED_JOBS`             | `true` to allow this runner to pick up jobs that have no tags. `false` is recommended.                                                    | `false`                                                    |
| `IS_LOCKED_TO_PROJECT`          | `true` to lock the runner to its registered project. `false` allows it to be enabled for other projects.                                  | `true`                                                     |
| `DOCKER_PULL_POLICY`            | The pull policy for job images: `always` or `if-not-present`.                                                                             | `if-not-present`                                           |
| **Docker Service Configuration**|                                                                                                                                         |                                                            |
| `RUNNER_IMAGE_NAME`             | The GitLab Runner image and tag to use for the service itself.                                                                          | `gitlab/gitlab-runner:v18.2.1`                             |
| `DOCKER_HELPER_IMAGE`           | The helper image used for cache/artifact handling. Should align with the runner version.                                                | `gitlab/gitlab-runner-helper:alpine3.19-x86_64-v18.2.1`    |
| `CONTAINER_NAME`                | The unique name for the Docker container running the service.                                                                           | `gitlab-runner-prod`                                       |
| `CONFIG_VOLUME_PATH`            | The host path to store the runner's persistent `config.toml`.                                                                           | `./prod-runner-config`                                     |
| `RESTART_POLICY`                | The container restart policy. `unless-stopped` is recommended for resilience.                                                           | `unless-stopped`                                           |
| `DOCKER_SOCKET_VOLUME_PATH`     | The path to the host's Docker socket. **Do not change unless you have a custom Docker setup.**                                          | `/var/run/docker.sock`                                     |
| **Performance Settings**        |                                                                                                                                         |                                                            |
| `RUNNER_CONCURRENT_JOBS`        | The total number of jobs this runner instance can execute simultaneously. A good starting point is the number of CPU cores on the host. | `4`                                                        |

## Verification

You can confirm the runner is working correctly in two ways:

1.  **On the Server:** Check that the Docker container is running.
    ```bash
    docker ps
    ```
    You should see your container (e.g., `gitlab-runner-prod`) in the list with status `Up`.

2.  **In GitLab:** Navigate to the **Settings > CI/CD > Runners** page. The new runner should appear with a green circle, indicating it has connected successfully. Click the "Edit" icon to verify that the tags and other settings match what you defined in your `.env` file.

## Project Structure

```
.
├── .gitignore              # Ignores local files like .env and config directories.
├── .env.example            # Template for all required environment variables.
├── LICENSE                 # MIT License file.
├── README.md               # This documentation file.
├── docker-compose.yml      # The core Docker Compose file for the runner service.
└── register-runner.sh      # The script to automate registration and configuration.
```

## Best Practices Implemented

-   **Infrastructure as Code (IaC)**: The entire runner setup is defined in version-controlled files, making it traceable and reproducible.
-   **Separation of Concerns**: Sensitive and environment-specific configuration (`.env`) is strictly separated from the deployment logic (`docker-compose.yml`, `register-runner.sh`).
-   **Explicit Declaration**: The system forces all configuration to be explicitly declared, avoiding ambiguity and "magic" default values that can cause confusion.
-   **Idempotency**: You can run `docker compose up -d` multiple times without negative side effects. The registration script is designed to be run once per new runner.

## Contributing

Contributions are welcome! If you find a bug, have a suggestion, or want to add a feature, please feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.