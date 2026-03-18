#!/usr/bin/env bash
set -euo pipefail

PX4_DIR="$HOME/px4-ros2-gazebo-ubuntu2004/PX4-Autopilot"

if [ ! -d "$PX4_DIR" ]; then
  echo "klonuje px4"
  git clone https://github.com/PX4/PX4-Autopilot.git --branch v1.14.3 --recursive "$PX4_DIR"
else
  echo "px4 zainstalowane w $PX4_DIR"
fi

echo "px4 gotowe"
