#!/usr/bin/env bash
set -euo pipefail

# runs apt in non-interactive mode so the script does not stop to ask questions
export DEBIAN_FRONTEND=noninteractive

ROS_DISTRO="foxy"
ROS_INSTALL_DIR="/opt/ros/${ROS_DISTRO}"
ROS_KEYRING="/usr/share/keyrings/ros-archive-keyring.gpg"
ROS_LIST_FILE="/etc/apt/sources.list.d/ros2.list"

log() {
  echo "[install_ros2] $*"
}

error() {
  echo "[install_ros2][ERROR] $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "command not found: $1"
}

check_ubuntu_version() {
  # srops early if this is not ubuntu 20.04.
  if [[ ! -f /etc/os-release ]]; then
    error "cannot detect operating system. /etc/os-release was not found."
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

is_there_ros() {
  # If ROS 2 Foxy is already installed in the standard location, skip the script.
  if [[ -d "${ROS_INSTALL_DIR}" ]]; then
    log "ROS 2 ${ROS_DISTRO} is already installed at ${ROS_INSTALL_DIR}. Skipping."
    exit 0
  fi
}

install_locales() {
  # ROS 2 expects a proper UTF-8 locale.
  log "Installing UTF-8 locales."

  sudo apt-get update
  sudo apt-get install -y locales
  sudo locale-gen en_US en_US.UTF-8
  sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

  export LANG=en_US.UTF-8
}

add_ros2_repo() {
  # These packages are needed to add the ROS 2 repository securely.
  log "Installing packages needed to add the ROS 2 repository."

  sudo apt-get update
  sudo apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common

  log "Enabling Ubuntu universe repository."
  sudo add-apt-repository universe -y

  # Store the ROS signing key in the apt keyring directory.
  if [[ ! -f "${ROS_KEYRING}" ]]; then
    log "Adding ROS 2 GPG key."
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      | sudo gpg --dearmor -o "${ROS_KEYRING}"
  else
    log "ROS 2 GPG key already exists."
  fi

  # Add the ROS 2 apt repository for Ubuntu 20.04.
  log "Adding ROS 2 apt repository."
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${ROS_KEYRING}] http://packages.ros.org/ros2/ubuntu focal main" \
    | sudo tee "${ROS_LIST_FILE}" >/dev/null
}

install_ros2_packages() {
  # ros-base is smaller than ros-desktop and is enough for many development tasks.
  log "Installing ROS 2 ${ROS_DISTRO} packages."

  sudo apt-get update
  sudo apt-get install -y \
    "ros-${ROS_DISTRO}-ros-base" \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete
}

setup_rosdep() {
  # rosdep helps install dependencies for ROS packages and workspaces.
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    log "Initializing rosdep."
    sudo rosdep init
  else
    log "rosdep is already initialized."
  fi

  log "Updating rosdep database."
  rosdep update
}

update_shell_config() {
  # Add ROS environment sourcing to .bashrc so it is available in new terminals.
  local source_line="source ${ROS_INSTALL_DIR}/setup.bash"

  touch "${HOME}/.bashrc"

  if ! grep -Fxq "${source_line}" "${HOME}/.bashrc"; then
    log "Adding ROS 2 environment setup to ${HOME}/.bashrc."
    echo "${source_line}" >> "${HOME}/.bashrc"
  else
    log "ROS 2 environment setup is already present in ${HOME}/.bashrc."
  fi
}

main() {
  log "Starting ROS 2 ${ROS_DISTRO} installation."

  require_command sudo
  require_command tee
  require_command dpkg

  check_ubuntu_version
  is_there_ros
  install_locales
  add_ros2_repo
  install_ros2_packages
  setup_rosdep
  update_shell_config

  log "ROS 2 ${ROS_DISTRO} installation completed successfully."
  log "Open a new terminal or run: source ${ROS_INSTALL_DIR}/setup.bash"
}

main "$@"
