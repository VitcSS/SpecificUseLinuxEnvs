#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================="
echo " Starting Light Dev WSL Setup (Debian)   "
echo "=========================================="

# 1. Update package lists
echo "--> Updating package repositories..."
sudo apt update

# 2. Configure APT to ignore recommended/suggested packages (Anti-Bloat)
echo "--> Configuring APT to skip unnecessary recommendations..."
sudo tee /etc/apt/apt.conf.d/99lightweight <<EOF
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

# 3. Upgrade existing packages
echo "--> Upgrading current system packages..."
sudo apt upgrade -y

# 4. Install essential, minimal development tools
echo "--> Installing core development tools..."
sudo apt install -y \
    build-essential \
    git \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    neovim

# 5. Clean up package cache to save disk space
echo "--> Cleaning up package cache..."
sudo apt autoremove -y
sudo apt clean

echo "=========================================="
echo " Setup Complete! Your light dev env is ready. "
echo "=========================================="
