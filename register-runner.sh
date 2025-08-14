#!/bin/bash
# ==============================================================================
# GitLab Runner Registration Script
# ==============================================================================
#
# DESCRIPTION:
# This script automates the GitLab Runner registration process. It is designed
# to be run after the 'docker-compose up -d' command has started the runner
# service. It reads configuration from the .env file and executes the
# non-interactive 'gitlab-runner register' command inside the running container.
#
# USAGE:
# ./register-runner.sh
#
# ==============================================================================
# --- Script Configuration and Safety ---
# Exit immediately if a command exits with a non-zero status. This prevents
# unexpected behavior and ensures the script stops if any step fails.
set -e

# --- Environment Validation ---
# 1. Check if the .env file exists.
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found."
    echo "Please copy an example .env file to .env and fill in all the required values."
    exit 1
fi

# 2. Load environment variables from the .env file into the current shell session.
export $(grep -v '^#' .env | xargs)

# 3. Check for the presence of ALL required variables.
# An error will be thrown if any of these are empty or not set.
if [ -z "$GITLAB_URL" ] || \
   [ -z "$REGISTRATION_TOKEN" ] || \
   [ -z "$RUNNER_DESCRIPTION" ] || \
   [ -z "$RUNNER_TAGS" ] || \
   [ -z "$RUNNER_EXECUTOR" ] || \
   [ -z "$DOCKER_IMAGE" ] || \
   [ -z "$RUN_UNTAGGED_JOBS" ] || \
   [ -z "$IS_LOCKED_TO_PROJECT" ] || \
   [ -z "$CONTAINER_NAME" ] || \
   [ -z "$CONFIG_VOLUME_PATH" ]; then
    echo "❌ Error: One or more required environment variables are not set in the .env file."
    echo "Please ensure all variables are defined."
    exit 1
fi

# --- Pre-Registration Checks ---
# Check if the target Docker container is running.
if [ ! "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "❌ Error: The runner container named '${CONTAINER_NAME}' is not running."
    echo "Please run 'docker-compose up -d' first."
    exit 1
fi

echo "✅ Pre-flight checks passed. Starting registration process..."
echo "---"
echo "   GitLab URL: $GITLAB_URL"
echo "   Description: $RUNNER_DESCRIPTION"
echo "   Tags: $RUNNER_TAGS"
echo "   Executor: $RUNNER_EXECUTOR"
echo "   Container: $CONTAINER_NAME"
echo "---"

# --- Registration Command ---
echo "🚀 Registering the runner with GitLab..."

# Execute the registration command inside the Docker container.
# This command now strictly uses the variables from the .env file with no defaults.
docker exec -it "$CONTAINER_NAME" gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$REGISTRATION_TOKEN" \
  --executor "$RUNNER_EXECUTOR" \
  --docker-image "$DOCKER_IMAGE" \
  --description "$RUNNER_DESCRIPTION" \
  --tag-list "$RUNNER_TAGS" \
  --run-untagged="$RUN_UNTAGGED_JOBS" \
  --locked="$IS_LOCKED_TO_PROJECT" \
  --access-level="not_protected"

echo "---"
echo "✅ Success! Registration Complete."
echo "The runner is now registered and connected to your GitLab instance."
echo "You can verify its status in the GitLab UI (Admin > CI/CD > Runners)."