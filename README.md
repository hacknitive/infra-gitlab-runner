<p align="center">
  <img src="./assets/avatar.jpeg" alt="Project Redis Docker Avatar" width="200">
</p>

# Ready-to-Use GitLab Runner Docker Infrastructure

This repository provides a standardized, flexible, and automated solution for deploying GitLab Runners using Docker and Docker Compose. It is designed to be easily configured for any environment (development, staging, production) by simply creating and defining a single `.env` file.

## Table of Contents
- [Ready-to-Use GitLab Runner Docker Infrastructure](#ready-to-use-gitlab-runner-docker-infrastructure)
  - [Table of Contents](#table-of-contents)
  - [Overview \& Features](#overview--features)
  - [Prerequisites](#prerequisites)
  - [Deployment in 5 Steps](#deployment-in-5-steps)
    - [Step 1: Clone the Repository](#step-1-clone-the-repository)
    - [Step 2: Create and Configure the `.env` File](#step-2-create-and-configure-the-env-file)
    - [Step 3: Launch the Runner Service](#step-3-launch-the-runner-service)
    - [Step 4: Register the Runner](#step-4-register-the-runner)
    - [Step 5: Final Configuration in GitLab UI](#step-5-final-configuration-in-gitlab-ui)
  - [Configuration Details (`.env` Variables)](#configuration-details-env-variables)
  - [Verification](#verification)
  - [Project Structure](#project-structure)
  - [Best Practices Implemented](#best-practices-implemented)

---

## Overview & Features
This project automates the entire process of setting up a GitLab Runner. It enforces a strict configuration-as-code approach with no default values.

-   ✅ **Strict & Explicit Configuration**: All settings are controlled via a `.env` file. The system will fail with a clear error if any variable is missing.
-   ✅ **Automated Registration**: A shell script reads your `.env` file and executes the non-interactive registration command, ensuring consistency.
-   ✅ **Docker Executor**: Configured to use the powerful and isolated Docker executor, allowing jobs to run in clean, containerized environments.
-   ✅ **Persistent & Stateless**: The runner's configuration is stored in a Docker volume on the host, so the runner container itself is stateless and survives restarts or re-creations.
-   ✅ **Reusable & Consistent**: Use the same repository and process to deploy runners on any server, ensuring consistency across all your environments.

## Prerequisites
-   A server (VM or physical) with root or Docker group access.
-   [Docker] and [Docker Compose] installed on that server.
-   A GitLab Runner **registration token** from your GitLab instance (found under **Project > Settings > CI/CD > Runners** or **Admin Area > CI/CD > Runners**).

## Deployment in 5 Steps
Follow these steps on the server where you want the runner to operate.

### Step 1: Clone the Repository
```bash
git clone https://github.com/hacknitive/infra-gitlab-runner.git
cd infra-gitlab-runner
```

### Step 2: Create and Configure the `.env` File
This is the **only manual configuration step**. Copy the example file and edit it with your values.

1.  **Create the `.env` file:**
    ```bash
    cp .env.example .env
    ```
2.  **Edit the `.env` file:**
    Open `.env` in a text editor (like `nano` or `vim`) and provide a value for **every variable**.
    ```dotenv
    # Example for a staging server
    GITLAB_URL="https://gitlab.yourcompany.com"
    REGISTRATION_TOKEN="your-secret-registration-token-here"
    RUNNER_DESCRIPTION="Staging Server Runner"
    RUNNER_TAGS="docker,staging"
    RUNNER_EXECUTOR="docker"
    DOCKER_IMAGE="alpine:latest"
    RUN_UNTAGGED_JOBS="false"
    IS_LOCKED_TO_PROJECT="false"
    CONTAINER_NAME="gitlab-runner-staging"
    CONFIG_VOLUME_PATH="./staging-runner-config"
    ```

### Step 3: Launch the Runner Service
This command starts the GitLab Runner container in the background. It will be running but not yet connected to your GitLab instance.
```bash
docker compose up -d
```
*If this command fails, it is likely because `CONTAINER_NAME` or `CONFIG_VOLUME_PATH` are not set in your `.env` file.*

### Step 4: Register the Runner
Run the automated registration script. This will connect the runner to your GitLab instance.

1.  **Make the script executable (only needs to be done once):**
    ```bash
    chmod +x register-runner.sh
    ```
2.  **Run the script:**
    ```bash
    ./register-runner.sh
    ```
The script will successfully register the runner. You will see a `WARNING` message about a "legacy-compatible registration process." This is expected. It means the runner is connected, but we must manually apply its specific behaviors in the next step.

### Step 5: Final Configuration in GitLab UI
Due to recent changes in GitLab, some settings must be configured manually after the initial registration. Your `.env` file remains the source of truth for what these settings should be.

1.  **Navigate to your GitLab project** or admin area.
2.  Go to **Settings > CI/CD** and expand the **Runners** section.
3.  Find your new runner (it will have the description you set, e.g., "Staging Server Runner") and click the **Edit** (pencil) icon.
4.  **Configure the following settings** to match your `.env` file:
    *   **Tags**: Add the tags from your `RUNNER_TAGS` variable (e.g., `docker,staging`).
    *   **Run untagged jobs**: Uncheck this box if `RUN_UNTAGGED_JOBS` is `false`.
    *   **Lock to current projects**: Check this box if `IS_LOCKED_TO_PROJECT` is `true`.
5.  Click **Save changes**.

Your runner is now fully configured and operational.

## Configuration Details (`.env` Variables)
All configuration is handled by these environment variables. **All variables are required.**

| Variable                 | Description                                                                                             | Example                               |
| :----------------------- | :------------------------------------------------------------------------------------------------------ | :------------------------------------ |
| `GITLAB_URL`             | The full URL of your GitLab instance.                                                                   | `https://gitlab.com`                  |
| `REGISTRATION_TOKEN`     | The secret registration token from the GitLab UI.                                                       | `glrt-xxxxxxxxxxxxxx`                 |
| `RUNNER_DESCRIPTION`     | A human-readable description for the runner in the UI.                                                  | `Production Runner (Web)`             |
| `RUNNER_TAGS`            | Comma-separated list of tags to assign to the runner. Crucial for job routing.                          | `docker,production,web`               |
| `RUNNER_EXECUTOR`        | The executor to use. `docker` is highly recommended.                                                    | `docker`                              |
| `DOCKER_IMAGE`           | The default Docker image to use for jobs if not specified in `.gitlab-ci.yml`.                          | `ruby:3.1`                            |
| `RUN_UNTAGGED_JOBS`      | Set to `true` to allow this runner to pick up jobs that have no tags. `false` is recommended.             | `false`                               |
| `IS_LOCKED_TO_PROJECT`   | Set to `false` for shared runners, `true` for specific runners.                                         | `true`                                |
| `CONTAINER_NAME`         | The name for the Docker container running the runner service.                                           | `gitlab-runner-prod`                  |
| `CONFIG_VOLUME_PATH`     | The path on the host machine to store the runner's persistent configuration (`config.toml`).              | `./prod-runner-config`                |

## Verification
You can confirm the runner is working correctly in two ways:

1.  **On the Server:** Check that the Docker container is running.
    ```bash
    docker ps
    ```
    You should see your container (e.g., `gitlab-runner-staging`) in the list.

2.  **In GitLab:** Navigate to the Runners page. The new runner should appear with a green circle, indicating it has connected successfully. Verify that the tags and lock status match the configuration you set in Step 5.

## Project Structure
```
.
├── .gitignore              # Ignores local files like .env and config directories.
├── .env.example            # Template for all required environment variables.
├── LICENSE
├── README.md               # This documentation file.
├── docker-compose.yml      # The core Docker Compose file for the runner service.
└── register-runner.sh      # The script to automate the registration process.
```

## Best Practices Implemented
-   **Infrastructure as Code (IaC)**: The entire runner setup is defined in version-controlled files.
-   **Separation of Concerns**: Sensitive configuration (`.env`) is strictly separated from the deployment logic (`docker-compose.yml`, `register-runner.sh`).
-   **Explicit Declaration**: The system forces all configuration to be explicitly declared, avoiding ambiguity and "magic" default values.
-   **Idempotency**: You can run `docker compose up -d` multiple times without negative side effects. The registration script should only be run once per runner.