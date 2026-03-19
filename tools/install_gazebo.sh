#!/usr/bin/env bash
set -euo pipefail

# Run apt in non-interactive mode so the script does not stop to ask questions.
export DEBIAN_FRONTEND=noninteractive

GAZEBO_PACKAGE="gz-garden"
GAZEBO_KEYRING="/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg"
GAZEBO_LIST_FILE="/etc/apt/sources.list.d/gazebo-stable.list"

log() {
  echo "[install_gazebo] $*"
}

error() {
  echo "[install_gazebo][ERROR] $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "Command not found: $1"
}

check_ubuntu_version() {
  # This project targets Ubuntu 20.04, so stop early on a different system.
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

  UBUNTU_CODENAME="${VERSION_CODENAME:-focal}"
  log "Detected Ubuntu ${VERSION_ID} (${UBUNTU_CODENAME})."
}

check_if_gazebo_is_already_installed() {
  # If the main Gazebo package is already installed, we skip the rest.
  if dpkg -s "${GAZEBO_PACKAGE}" >/dev/null 2>&1; then
    log "${GAZEBO_PACKAGE} is already installed. Skipping."
    exit 0
  fi
}

install_repository_dependencies() {
  # These packages are needed to add the external Gazebo repository securely.
  log "Installing packages needed to add the Gazebo repository."

  sudo apt-get update
  sudo apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    ca-certificates
}

add_gazebo_repository() {
  # Gazebo packages are distributed through the OSRF repository.
  # We store the signing key in the apt keyring directory.
  if [[ ! -f "${GAZEBO_KEYRING}" ]]; then
    log "Adding Gazebo GPG key."
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
      | sudo gpg --dearmor -o "${GAZEBO_KEYRING}"
  else
    log "Gazebo GPG key already exists."
  fi

  log "Adding Gazebo apt repository."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${GAZEBO_KEYRING}] http://packages.osrfoundation.org/gazebo/ubuntu-stable focal main" \
    | sudo tee "${GAZEBO_LIST_FILE}" >/dev/null
}

install_gazebo_packages() {
  # We install the modern Gazebo package because the PX4 run target uses `gz_x500`.
  log "Installing ${GAZEBO_PACKAGE}."

  sudo apt-get update
  sudo apt-get install -y "${GAZEBO_PACKAGE}"
}

verify_installation() {
  # A simple final check so the user gets a clear error if the package was not installed.
  if ! command -v gz >/dev/null 2>&1; then
    error "Gazebo installation finished, but the 'gz' command was not found."
  fi

  log "Gazebo command detected: $(command -v gz)"
}

main() {
  log "Starting Gazebo installation."

  require_command sudo
  require_command tee
  require_command dpkg

  check_ubuntu_version
  check_if_gazebo_is_already_installed
  install_repository_dependencies
  add_gazebo_repository
  install_gazebo_packages
  verify_installation

  log "Gazebo installation completed successfully."
}

main "$@"
