#!/bin/bash
# PostmarketOS Build Script for GitHub Actions CI
set -ex

# Allow running as root (needed for CI chroot operations)
export PMBOOTSTRAP_ALLOW_RUNNING_AS_ROOT=1

WORK_DIR="/tmp/pmbootstrap-work"
CONFIG="/tmp/pmbootstrap.cfg"

# Clone pmbootstrap
echo "=== Cloning pmbootstrap ==="
git clone --depth 1 https://gitlab.postmarketos.org/postmarketOS/pmbootstrap.git /tmp/pmbootstrap

# Patch pmbootstrap to allow running as root (needed for CI)
echo "=== Patching pmbootstrap for root access ==="
# Find and patch the root check
ROOT_CHECK_FILE=$(grep -rl "Do not run pmbootstrap as root" /tmp/pmbootstrap/pmb/ 2>/dev/null | head -1)
if [ -n "$ROOT_CHECK_FILE" ]; then
    echo "Found root check in: $ROOT_CHECK_FILE"
    cat "$ROOT_CHECK_FILE"
    # Comment out the entire root check block
    sed -i 's/if os.geteuid() == 0:/if False:  # Patched for CI/' "$ROOT_CHECK_FILE"
    echo "=== After patching ==="
    cat "$ROOT_CHECK_FILE"
fi

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
cat > "$CONFIG" << 'ENDCONFIG'
[pmbootstrap]
aports = /tmp/pmbootstrap-work/cache_git/pmaports
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
work = /tmp/pmbootstrap-work
boot_size = 256
extra_space = 0
sudo_timer = False

[providers]
ENDCONFIG

echo "=== Config file ==="
cat "$CONFIG"

# Check pmbootstrap status
echo "=== pmbootstrap status ==="
/tmp/pmbootstrap/pmbootstrap.py -c "$CONFIG" status || true

# Build
echo "=== Starting build ==="
/tmp/pmbootstrap/pmbootstrap.py -c "$CONFIG" -v install

# Export
echo "=== Exporting images ==="
mkdir -p /tmp/pmos-output
/tmp/pmbootstrap/pmbootstrap.py -c "$CONFIG" export /tmp/pmos-output/
ls -la /tmp/pmos-output/
