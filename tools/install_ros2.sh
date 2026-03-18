#!/usr/bin/env bash
set -euo pipefail

log(){
  echo "instalowanie rosa2"
}

error(){
  echo "ros2 sie wykrzaczyl" >&2
  exit 1
}

which_ubuntu(){
  if [[ ! -r /etc/os-release ]]; then
    error "nie widzi systemu bo ni ma/etc/os-release"
}
  fi

  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    error "instalacja ros2 wpierana tylko na ubuntu"
  fi

  UBUNTU_VERSION="${VERSION_ID:-unknown}"
  UBUNTU_CODENAME="${VERSION_CODENAME:-unknown}"

  case "${UBUNTU_VERSION}" in
  "20.04")
    ROS_DISTRO="foxy"
    ;;
  "22.04")
    ROS_DISTRO="humble"
    ;;
  *)

    error "brak wsparcia ${UBUNTU_VERSION}"
    ;;
  
  esac

  log "Detected Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME}). Selected ROS 2 distro: ${ROS_DISTRO}."

main() {
  which_ubuntu

  log "instalowanie paczek lokalnych"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y locales
  
}
