#!/usr/bin/env bash
set -euo pipefail

# AOSA Linux system dependencies installer

if command -v apt-get &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y \
    libsecret-1-dev \
    libkeybinder-3.0-dev \
    libappindicator3-dev \
    libgtk-3-dev \
    libjsoncpp-dev
elif command -v dnf &>/dev/null; then
  sudo dnf install -y \
    libsecret-devel \
    keybinder3-devel \
    libappindicator-gtk3-devel \
    gtk3-devel \
    jsoncpp-devel
elif command -v pacman &>/dev/null; then
  sudo pacman -S --noconfirm \
    libsecret \
    keybinder3 \
    libappindicator-gtk3 \
    gtk3 \
    jsoncpp
else
  echo "Unsupported package manager. Install manually:"
  echo "  libsecret-1, keybinder-3.0, appindicator3-0.1, gtk3, jsoncpp"
  exit 1
fi

echo "All Linux dependencies installed."
