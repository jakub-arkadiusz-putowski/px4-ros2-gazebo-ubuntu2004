#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="px4-ros2-gazebo-ubuntu2004"
REPO_OWNER="jakub-arkadiusz-putowski"
REPO_BRANCH="main"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
INSTALl_DIR="${HOME}/${REPO_NAME}"

PX4_DIR="${INSTAL_DIR}/PX4-Autopilot"
PX4_REPO="https://github.com/PX4/PX4-Autopilot.git"

ROS_DISTRO="foxy"


if [ ! -d "$INSTALL_DIR" ]; then
  echo "klonowanie do $INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
else
  echo "aktualizacja '$REPO_NAME'"
  cd "$REPO_NAME" && git pull origin main
fi


cd "$INSTALL_DIR"
chmod +x tools/*.sh

#zaleznosci?
echo "instalacja zaleznosci"
./tools/install_dependencies.sh
./tools/download_px4.sh
