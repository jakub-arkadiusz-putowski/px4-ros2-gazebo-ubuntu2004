#!/usr/bin/env bash
set -euo pipefail

# To run apt in non-interactive mode (only relevant if called during setups)
export DEBIAN_FRONTEND=noninteractive

REPO_NAME="px4-ros2-gazebo-ubuntu2004"
INSTALL_DIR="${HOME}/${REPO_NAME}"
PX4_DIR="${INSTALL_DIR}/PX4-Autopilot"
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
  # This repository targets Ubuntu 20.04
  if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect operating system. /etc/os-release was not found."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    error "This launcher supports Ubuntu only."
  fi

  if [[ "${VERSION_ID:-}" != "20.04" ]]; then
    error "This launcher is intended for Ubuntu 20.04. Detected: ${VERSION_ID:-unknown}"
  fi

  log "Detected Ubuntu ${VERSION_ID} (${VERSION_CODENAME:-unknown})."
}

check_px4_directory() {
  # Verify if PX4 was downloaded and compiled
  if [[ ! -d "${PX4_DIR}" ]]; then
    error "PX4 directory was not found: ${PX4_DIR}. Please run the installation script first."
  fi

  if [[ ! -f "${PX4_DIR}/Makefile" ]]; then
    error "Makefile not found in ${PX4_DIR}. Is the PX4 clone complete?"
  fi

  log "PX4 source directory found at ${PX4_DIR}."
}

source_ros_environment() {
  if [[ ! -f "${ROS_SETUP_FILE}" ]]; then
    error "ROS 2 setup file not found at ${ROS_SETUP_FILE}. Please install ROS 2 first."
  fi

  log "Sourcing ROS 2 ${ROS_DISTRO} environment."

  # Temporarily disable strict unbound variable checking (+u)
  # because official ROS 2 setup scripts use unset variables (e.g. AMENT_TRACE_SETUP_FILES).
  set +u
  source "${ROS_SETUP_FILE}"
  set -u
}

configure_graphics() {
  log "Configuring graphics environment for Gazebo..."

  # Explicitly tell PX4 to use the modern Gazebo architecture
  export GZ_VERSION="garden"

  # Determine session type (X11 or Wayland)
  local session_type="${XDG_SESSION_TYPE:-x11}"
  log "Detected session type: ${session_type}"

  if [[ "${session_type}" == "wayland" ]]; then
    log "Wayland detected. Forcing Qt to use XCB backend for Gazebo compatibility."
    export QT_QPA_PLATFORM=xcb
  fi

  # Check if hardware acceleration is available (Fix for "libEGL warning: DRI2")
  # We check if glxinfo command exists (comes with mesa-utils), if not, we assume we might need software rendering.
  if command -v glxinfo >/dev/null 2>&1; then
    if glxinfo | grep -q "llvmpipe\|softpipe\|SVGA3D"; then
      log "Software rendering (Virtual Machine / No GPU) detected. Applying EGL fixes."
      export LIBGL_ALWAYS_SOFTWARE=1
      export MESA_GL_VERSION_OVERRIDE=3.3
    else
      log "Hardware acceleration (GPU) detected. Running natively."
    fi
  else
    log "glxinfo not found (mesa-utils missing). Applying safe software rendering fallback just in case."
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_GL_VERSION_OVERRIDE=3.3
  fi
}

run_px4_sitl() {
  log "Navigating to PX4 directory: ${PX4_DIR}"
  cd "${PX4_DIR}"

  log "======================================================================"
  log "🚀 Launching PX4 SITL with Gazebo target: make px4_sitl gz_x500"
  log "⚠️  NOTE: If this is your FIRST time running this command,"
  log "   PX4 will compile its C++ codebase from scratch."
  log "   This might take 3-10 minutes and look frozen. Please be patient!"
  log "   Subsequent runs will launch almost instantly."
  log "======================================================================"

  make px4_sitl gz_x500
}

main() {
  log "Starting PX4 SITL launcher."

  check_ubuntu_version
  check_px4_directory
  source_ros_environment
  configure_graphics
  run_px4_sitl
}

main "$@"
