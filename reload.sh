#!/bin/bash

# Prepares the environment to execute this script.
function prepareToExecute() {
  # Loads utility functions.
  source functions.sh

  showBanner

  cd iac || exit 1

  # Loads the environment variables.
  source .env
}

# Reloads the stack locally.
function reload() {
  $DOCKER_CMD compose down
  $DOCKER_CMD compose up -d

  echo "Reloaded!"
}

# Main function.
function main() {
  prepareToExecute
  checkDependencies
  reload
}

main