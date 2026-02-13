#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
source .env

sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  locales \
  bash-completion \
  cron \
  curl \
  vim \
  make \
  htop \
  tree \
  git

sudo apt autoremove -y && sudo apt autoclean -y

sudo locale-gen en_US.UTF-8

# Install docker
if ! command -v docker; then
  # See https://docs.docker.com/engine/install/debian/
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update

  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "Done."

vimrc_path="$HOME/.vimrc"
if [[ ! -f $vimrc_path ]]; then
  home_dir="${INFRA_DIR:?}"
  sudo cp "$home_dir/config/.vimrc" $vimrc_path
  sudo chown ops:ops $vimrc_path
fi
