#!/usr/bin/env bash
set -euo pipefail

source /etc/os-release
if [[ "$VERSION_ID" != "20.04" ]];then
  echo "wymaga ub20.04"
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  software-properties-common \
  curl \
  git \
  wget \
  python3-pip \
  python3-venv \
  make \
  gcc \
  g++ \
  build-essential

echo "zainstalowano zaleznosci"
