#!/bin/bash
# PostmarketOS Build Script for xiaomi-cactus (MT6739)
# Run this on any x86_64 Linux machine (cloud VM, WSL, etc.)
#
# Requirements:
# - x86_64 Linux (Ubuntu, Debian, Alpine, etc.)
# - Root access (for chroot operations)
# - ~10GB free disk space
# - Internet connection
#
# Usage:
#   chmod +x build-pmos.sh
#   sudo ./build-pmos.sh
#
# Output will be in ./pmos-output/

set -e

DEVICE="xiaomi-cactus"
WORK_DIR="$HOME/.local/var/pmbootstrap"
OUTPUT_DIR="./pmos-output"

echo "=== PostmarketOS Build Script for $DEVICE ==="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo ./build-pmos.sh"
    exit 1
fi

# Detect distro and install dependencies
if command -v apt-get &> /dev/null; then
    echo "[1/6] Installing dependencies (Debian/Ubuntu)..."
    apt-get update
    apt-get install -y python3 python3-pip git sudo bash coreutils openssl \
        kpartx e2fsprogs dosfstools parted util-linux multipath-tools \
        curl wget tar gzip xz-utils bzip2 file patch make gcc

elif command -v apk &> /dev/null; then
    echo "[1/6] Installing dependencies (Alpine)..."
    apk add --no-cache python3 py3-pip git sudo bash coreutils openssl \
        kpartx losetup e2fsprogs dosfstools parted util-linux multipath-tools \
        curl wget tar gzip xz bzip2 file patch make gcc musl-dev linux-headers

elif command -v dnf &> /dev/null; then
    echo "[1/6] Installing dependencies (Fedora)..."
    dnf install -y python3 python3-pip git sudo bash coreutils openssl \
        kpartx e2fsprogs dosfstools parted util-linux device-mapper-multipath \
        curl wget tar gzip xz bzip2 file patch make gcc

else
    echo "Unsupported distribution. Please install dependencies manually."
    exit 1
fi

echo ""
echo "[2/6] Cloning pmbootstrap..."
if [ -d "pmbootstrap" ]; then
    cd pmbootstrap && git pull && cd ..
else
    git clone https://gitlab.com/postmarketOS/pmbootstrap.git
fi

echo ""
echo "[3/6] Setting up work directory..."
mkdir -p "$WORK_DIR"
echo '8' > "$WORK_DIR/version"

# Clone pmaports if needed
if [ ! -d "$WORK_DIR/cache_git/pmaports" ]; then
    echo "    Cloning pmaports repository..."
    mkdir -p "$WORK_DIR/cache_git"
    git clone --depth 1 https://gitlab.com/postmarketOS/pmaports.git "$WORK_DIR/cache_git/pmaports"
fi

echo ""
echo "[4/6] Creating pmbootstrap config..."
mkdir -p ~/.config
cat > ~/.config/pmbootstrap.cfg << EOF
[pmbootstrap]
aports = $WORK_DIR/cache_git/pmaports
ccache_size = 5G
channel = master
device = $DEVICE
extra_packages = none
hostname = cactus
build_pkgs_on_install = True
jobs = $(nproc)
kernel =
keymap =
locale = en_US.UTF-8
mirror_alpine = http://dl-cdn.alpinelinux.org/alpine/
mirrors_postmarketos = http://mirror.postmarketos.org/postmarketos/
nonfree_firmware = True
nonfree_userland = False
ssh_keys = True
ssh_key_glob = ~/.ssh/id_*.pub
timezone = GMT
ui = none
ui_extras = False
user = user
work = $WORK_DIR
boot_size = 256
extra_space = 0
sudo_timer = False

[providers]
EOF

echo ""
echo "[5/6] Building PostmarketOS image..."
echo "    This may take 30-60 minutes..."
./pmbootstrap/pmbootstrap.py install

echo ""
echo "[6/6] Exporting images..."
mkdir -p "$OUTPUT_DIR"
./pmbootstrap/pmbootstrap.py export "$OUTPUT_DIR"

echo ""
echo "=== Build Complete ==="
echo ""
echo "Output files in: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
echo ""
echo "Transfer these files to your Mac and flash with:"
echo "  fastboot flash boot boot.img"
echo "  fastboot flash userdata xiaomi-cactus.img"
echo "  fastboot reboot"
