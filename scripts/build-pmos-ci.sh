#!/bin/bash
# PostmarketOS Build Script for GitHub Actions CI
set -ex

export HOME=/home/builder
WORK_DIR="/home/builder/pmbootstrap-work"
CONFIG="/home/builder/.config/pmbootstrap.cfg"

# Clone pmbootstrap
echo "=== Cloning pmbootstrap ==="
git clone --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git /home/builder/pmbootstrap

# Setup work directory
echo "=== Setting up work directory ==="
mkdir -p "$WORK_DIR"
echo "8" > "$WORK_DIR/version"

# Clone pmaports
echo "=== Cloning pmaports ==="
mkdir -p "$WORK_DIR/cache_git"
git clone --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmaports.git "$WORK_DIR/cache_git/pmaports"

# Create config
echo "=== Creating config ==="
mkdir -p /home/builder/.config
cat > "$CONFIG" << 'ENDCONFIG'
[pmbootstrap]
aports = /home/builder/pmbootstrap-work/cache_git/pmaports
ccache_size = 5G
channel = master
device = xiaomi-cactus
extra_packages = none
hostname = pmos
build_pkgs_on_install = True
jobs = 4
kernel =
keymap =
locale = en_US.UTF-8
mirror_alpine = http://dl-cdn.alpinelinux.org/alpine/
mirrors_postmarketos = http://mirror.postmarketos.org/postmarketos/
nonfree_firmware = True
nonfree_userland = False
ssh_keys = False
ssh_key_glob = ~/.ssh/id_*.pub
timezone = GMT
ui = none
ui_extras = False
user = user
work = /home/builder/pmbootstrap-work
boot_size = 256
extra_space = 0
sudo_timer = False

[providers]
ENDCONFIG

echo "=== Config file ==="
cat "$CONFIG"

# Check pmbootstrap status
echo "=== pmbootstrap status ==="
/home/builder/pmbootstrap/pmbootstrap.py -c "$CONFIG" status || true

# Build
echo "=== Starting build ==="
/home/builder/pmbootstrap/pmbootstrap.py -c "$CONFIG" -v install

# Export
echo "=== Exporting images ==="
mkdir -p /home/builder/output
/home/builder/pmbootstrap/pmbootstrap.py -c "$CONFIG" export /home/builder/output/
ls -la /home/builder/output/
