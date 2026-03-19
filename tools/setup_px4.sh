#!/usr/bin/env bash
set -euo pipefail

# Run apt in non-interactive mode so PX4 setup does not stop to ask questions.
export DEBIAN_FRONTEND=noninteractive

REPO_NAME="px4-ros2-gazebo-ubuntu2004"
PX4_DIR="${HOME}/${REPO_NAME}/PX4-Autopilot"
PX4_SETUP_SCRIPT="${PX4_DIR}/Tools/setup/ubuntu.sh"

log() {
  echo "[setup_px4] $*"
}

error() {
  echo "[setup_px4][ERROR] $*" >&2
  exit 1
}

check_ubuntu_version() {
  # This repository targets Ubuntu 20.04, so we stop early on a different system.
  if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect operating system. /etc/os-release was not found."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    error "This installer supports Ubuntu only."
  fi

  if [[ "${VERSION_ID:-}" != "20.04" ]]; then
    error "This installer is intended for Ubuntu 20.04. Detected: ${VERSION_ID:-unknown}"
  fi

  log "Detected Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-unknown})."
}

check_px4_directory() {
  # PX4 should already be cloned by download_px4.sh.
  if [[ ! -d "${PX4_DIR}" ]]; then
    error "PX4 directory was not found: ${PX4_DIR}"
  fi

  if [[ ! -f "${PX4_SETUP_SCRIPT}" ]]; then
    error "PX4 setup script was not found: ${PX4_SETUP_SCRIPT}"
  fi

  log "PX4 source directory found at ${PX4_DIR}."
}

prepare_px4_submodules() {
  # Submodules are important in PX4. Even if they were already fetched earlier,
  # running this again is harmless and helps avoid half-finished clones.
  log "Updating PX4 submodules."

  git -C "${PX4_DIR}" submodule update --init --recursive
}

run_px4_setup() {
  # PX4 ships its own Ubuntu setup script, so we use the official setup path here.
  # This is the easiest way to stay close to what PX4 expects.
  log "Running the official PX4 Ubuntu setup script."

  (
    cd "${PX4_DIR}"
    bash ./Tools/setup/ubuntu.sh
  )
}

final_notes() {
  log "PX4 setup completed successfully."
  log "If this was the first installation, opening a new terminal is recommended."
}

main() {
  log "Starting PX4 setup."

  check_ubuntu_version
  check_px4_directory
  prepare_px4_submodules
  run_px4_setup
  final_notes
}

main "$@"
