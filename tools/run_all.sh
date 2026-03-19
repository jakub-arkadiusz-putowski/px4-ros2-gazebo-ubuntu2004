#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="px4-ros2-gazebo-ubuntu2004"
REPO_OWNER="jakub-arkadiusz-putowski"
REPO_BRANCH="main"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
INSTALL_DIR="${HOME}/${REPO_NAME}"

log() {
  echo "[run_all] $*"
}

error() {
  echo "[run_all][ERROR] $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "Command not found: $1"
}

check_repo() {
  # This script is designed to be run directly through curl,
  # so it has to make sure the local repository exists first.
  if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
    log "Local repository was not found. Cloning into ${INSTALL_DIR}."
    git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
  else
    log "Local repository found in ${INSTALL_DIR}."
    log "Updating repository."
    git -C "${INSTALL_DIR}" fetch origin
    git -C "${INSTALL_DIR}" checkout "${REPO_BRANCH}"
    git -C "${INSTALL_DIR}" pull --ff-only origin "${REPO_BRANCH}"
  fi
}

check_run_script() {
  if [[ ! -f "${INSTALL_DIR}/tools/run_px4_sitl.sh" ]]; then
    error "Run script not found: ${INSTALL_DIR}/tools/run_px4_sitl.sh"
  fi
}

main() {
  log "Starting run entrypoint."

  require_command git
  require_command bash

  check_repo
  check_run_script

  cd "${INSTALL_DIR}"

  log "Running PX4 SITL launcher."
  bash tools/run_px4_sitl.sh
}

main "$@"
