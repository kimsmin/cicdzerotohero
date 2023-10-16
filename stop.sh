#!/bin/bash

function prepareToExecute() {
  source functions.sh

  showBanner
}

function stop() {
  cd iac || exit 1

  source .env

  $DOCKER_CMD compose down

  echo "Stopped!"
}

function main() {
  prepareToExecute
  checkDependencies
  stop
}

main