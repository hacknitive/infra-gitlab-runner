#!/bin/bash
# ==============================================================================
# GitLab Runner Registration and Configuration Script
# ==============================================================================
#
# DESCRIPTION:
# This script fully automates the GitLab Runner setup process. It performs
# three key actions in sequence:
# 1. Registers a new runner, which creates the initial config.toml.
# 2. Sets the global 'concurrent' value in the newly created config.toml.
# 3. Restarts the runner container to apply all configuration changes.
#
# USAGE:
# Ensure the .env file is complete, then run: ./register-runner.sh
#
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Step 0: Environment Validation ---
echo "▶️ [Step 0/4] Validating environment..."
if [ ! -f ".env" ]; then
    echo "❌ FATAL: .env file not found. Please copy .env.example to .env and fill it out."
    exit 1
fi

# Load environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Define all required variables in an array
REQUIRED_VARS=(
    "GITLAB_URL"
    "REGISTRATION_TOKEN"
    "RUNNER_DESCRIPTION"
    "RUNNER_TAGS"
    "RUNNER_EXECUTOR"
    "RUNNER_DEFAULT_DOCKER_IMAGE"
    "RUN_UNTAGGED_JOBS"
    "IS_LOCKED_TO_PROJECT"
    "RUNNER_IMAGE_NAME"
    "CONTAINER_NAME"
    "CONFIG_VOLUME_PATH"
    "RUNNER_CONCURRENT_JOBS"
    "DOCKER_PULL_POLICY"
    "DOCKER_HELPER_IMAGE"
)

# Loop through the array to check if each variable is set
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "❌ FATAL: Environment variable '$VAR' is not set in the .env file."
        exit 1
    fi
done
echo "✅ Environment validation passed."
echo "---"

# --- Pre-flight Check: Ensure runner container is running ---
echo "▶️ [Step 1/4] Checking for running runner container..."
if [ ! "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "❌ FATAL: The runner container named '${CONTAINER_NAME}' is not running."
    echo "   Please run 'docker compose up -d' first."
    exit 1
fi
echo "✅ Container '${CONTAINER_NAME}' is running."
echo "---"

# --- Step 2: Register the New Runner ---
# We do this first because the register command creates the config.toml file.
echo "▶️ [Step 2/4] Registering the new runner with GitLab..."
echo "   GitLab URL: $GITLAB_URL"
echo "   Description: $RUNNER_DESCRIPTION"
echo "   Executor: $RUNNER_EXECUTOR"

# Execute the registration command non-interactively inside the container.
docker exec "$CONTAINER_NAME" gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$REGISTRATION_TOKEN" \
  --executor "$RUNNER_EXECUTOR" \
  --docker-image "$RUNNER_DEFAULT_DOCKER_IMAGE" \
  --description "$RUNNER_DESCRIPTION" \
  --tag-list "$RUNNER_TAGS" \
  --run-untagged="$RUN_UNTAGGED_JOBS" \
  --locked="$IS_LOCKED_TO_PROJECT" \
  --access-level="not_protected" \
  --docker-pull-policy "$DOCKER_PULL_POLICY" \
  --docker-helper-image "$DOCKER_HELPER_IMAGE" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"

echo "✅ Registration command sent. config.toml is now created."
echo "---"

# --- Step 3: Configure Global Settings in config.toml ---
# Now that the file is guaranteed to exist, we can safely modify it.
echo "▶️ [Step 3/4] Setting global concurrent jobs to '$RUNNER_CONCURRENT_JOBS'..."
docker exec "$CONTAINER_NAME" \
  sed -i "s/concurrent = .*/concurrent = ${RUNNER_CONCURRENT_JOBS}/" /etc/gitlab-runner/config.toml

# Verify the change
CONCURRENT_VALUE=$(docker exec "$CONTAINER_NAME" grep "concurrent =" /etc/gitlab-runner/config.toml)
echo "✅ Global configuration updated: ${CONCURRENT_VALUE}"
echo "---"

# --- Step 4: Restart the Runner to Apply All Changes ---
echo "▶️ [Step 4/4] Restarting the runner container to apply all changes..."
docker restart "$CONTAINER_NAME" > /dev/null
echo "✅ Container restarted successfully."
echo "---"

echo "🎉 SUCCESS! Full configuration and registration complete."
echo "The runner has been restarted and should now be visible in your GitLab UI."
echo "Please verify its status and settings in the GitLab Runners admin area."