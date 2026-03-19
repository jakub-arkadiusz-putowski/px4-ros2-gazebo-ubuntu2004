#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="px4-ros2-gazebo-ubuntu2004"
PX4_DIR="${HOME}/${REPO_NAME}/PX4-Autopilot"
ROS_DISTRO="foxy"
ROS_SETUP_FILE="/opt/ros/${ROS_DISTRO}/setup.bash"

log() {
  echo "[run_px4_sitl] $*"
}

error() {
  echo "[run_px4_sitl][ERROR] $*" >&2
  exit 1
}

check_ubuntu_version() {
  # This project targets Ubuntu 20.04, so stop early on a different system.
  if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect operating system. /etc/os-release was not found."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    error "This script supports Ubuntu only."
  fi

  if [[ "${VERSION_ID:-}" != "20.04" ]]; then
    error "This script is intended for Ubuntu 20.04. Detected: ${VERSION_ID:-unknown}"
  fi

  log "Detected Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-unknown})."
}

check_px4_directory() {
  # PX4 should already be cloned during installation.
  if [[ ! -d "${PX4_DIR}" ]]; then
    error "PX4 directory was not found: ${PX4_DIR}"
  fi

  if [[ ! -f "${PX4_DIR}/Makefile" ]]; then
    error "PX4 Makefile was not found in ${PX4_DIR}"
  fi

  log "PX4 source directory found at ${PX4_DIR}."
}

source_ros_environment() {
  # ROS 2 setup scripts are not always friendly with `set -u`,
  # so we temporarily disable nounset before sourcing them.
  if [[ -f "${ROS_SETUP_FILE}" ]]; then
    log "Sourcing ROS 2 ${ROS_DISTRO} environment."
    set +u
    # shellcheck disable=SC1090
    source "${ROS_SETUP_FILE}"
    set -u
  else
    log "ROS 2 setup file was not found at ${ROS_SETUP_FILE}. Continuing without sourcing ROS 2."
  fi
}

run_px4_sitl() {
  log "Starting PX4 SITL with Gazebo target: make px4_sitl gz_x500"

  cd "${PX4_DIR}"
  make px4_sitl gz_x500
}

main() {
  log "Starting PX4 SITL launcher."

  check_ubuntu_version
  check_px4_directory
  source_ros_environment
  run_px4_sitl
}

main "$@"
