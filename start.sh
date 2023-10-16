#!/bin/bash

function prepareToExecute() {
  source functions.sh

  showBanner
}

function start() {
  cd iac || exit 1

  source .env

  $DOCKER_CMD compose up -d

  echo "Started!"
}

function main() {
  prepareToExecute
  checkDependencies
  start
}

main