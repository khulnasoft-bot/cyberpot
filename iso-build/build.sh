#!/bin/bash

# This script builds a bootable Debian ISO that automatically installs CyberPot.

# Exit on any error
set -e

# --- Configuration ---
# Distribution settings
DISTRO="bookworm"
MIRROR="http://deb.debian.org/debian/"

# ISO settings
ISO_NAME="cyberpot-installer.iso"
ISO_LABEL="CYBERPOT"

# Workspace
BUILD_DIR=$(mktemp -d -p /tmp)
CHROOT_DIR="${BUILD_DIR}/chroot"
ISO_DIR="${BUILD_DIR}/iso"
CUSTOM_SCRIPTS_DIR="custom-scripts"

# --- Functions ---

# Function to display an error message and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
function command_exists {
    command -v "$1" >/dev/null 2>&1
}

# Get the absolute path of the project root
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# --- Main Script ---

# Check if the script is being run from the root of the project
if [ ! -f "install.sh" ]; then
    error_exit "This script must be run from the root of the CyberPot project."
fi

# Change into the iso-build directory
cd iso-build

# Check if running in a Docker container
if [ -f /.dockerenv ]; then
    echo "Warning: This script is running inside a Docker container."
    echo "The build may fail if the container is not run with the --privileged flag."
fi

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root."
fi


# Function to wait for apt lock
function wait_for_apt {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for other software managers to finish..."
        sleep 5
    done
}

# Check for required tools
REQUIRED_TOOLS="debootstrap xorriso mksquashfs"
MISSING_TOOLS=""

for tool in $REQUIRED_TOOLS; do
    if ! command_exists "$tool"; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

# Also check for isolinux files and the keyring
if [ ! -f /usr/lib/ISOLINUX/isolinux.bin ] || [ ! -f /usr/lib/syslinux/modules/bios/menu.c32 ]; then
    MISSING_TOOLS="$MISSING_TOOLS isolinux syslinux-common"
fi

# Specifically check for debian-archive-keyring
if [ ! -f /usr/share/keyrings/debian-archive-keyring.gpg ]; then
    MISSING_TOOLS="$MISSING_TOOLS debian-archive-keyring"
fi

if [ -n "$MISSING_TOOLS" ]; then
    echo "Installing missing tools and dependencies: $MISSING_TOOLS"
    wait_for_apt
    apt-get update
    apt-get install -y --no-install-recommends debootstrap xorriso squashfs-tools isolinux syslinux-common debian-archive-keyring psmisc
fi

# Check for privileged mode (required for mounting in debootstrap/chroot)
if [ -f /.dockerenv ] && ! mount -t proc proc /proc >/dev/null 2>&1; then
    echo "Error: This container doesn't seem to have sufficient privileges (missing --privileged or CAP_SYS_ADMIN)."
    echo "Mounting operations will likely fail."
fi

# Clean up previous builds
echo "Cleaning up previous builds..."
rm -rf "${BUILD_DIR}"

# Create build directories
echo "Creating build directories..."
mkdir -p "${CHROOT_DIR}" "${ISO_DIR}/isolinux" "${ISO_DIR}/live" "${CUSTOM_SCRIPTS_DIR}"

# Determine keyring
# On some systems (Ubuntu) it might be in a different spot or debootstrap might need help finding it
KEYRING_PATHS=(
    "/usr/share/keyrings/debian-archive-keyring.gpg"
    "/usr/share/keyrings/ubuntu-archive-keyring.gpg"
)

KEYRING_ARG=""
for path in "${KEYRING_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "Using keyring: $path"
        KEYRING_ARG="--keyring=$path"
        break
    fi
done

if [ -z "$KEYRING_ARG" ]; then
    echo "Warning: No Debian/Ubuntu archive keyring found. Debootstrap might fail or warn about signatures."
    # We could add --no-check-gpg here if we really wanted to force it, but better to try default first
fi

# Stage 1: Create a minimal Debian system
echo "Debootstrapping Debian ${DISTRO}..."
# Using --no-check-gpg as a last resort if it still fails in certain environments
debootstrap ${KEYRING_ARG} --arch amd64 --variant=minbase "${DISTRO}" "${CHROOT_DIR}" "${MIRROR}"

# Stage 2: Configure the chroot environment
echo "Configuring the chroot environment..."

# Mount pseudo-filesystems
mount --bind /dev "${CHROOT_DIR}/dev"
mount -t proc proc "${CHROOT_DIR}/proc"
mount -t sysfs sysfs "${CHROOT_DIR}/sys"

# Set up networking
cp /etc/resolv.conf "${CHROOT_DIR}/etc/resolv.conf"

# Stage 3: Install packages in the chroot
echo "Installing packages in the chroot..."
chroot "${CHROOT_DIR}" /bin/bash <<'EOF'
# Exit on any error
set -e

# Set a non-interactive frontend to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Update package lists
apt-get update

# Install kernel, bootloader, and other necessary packages
apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    systemd-sysv \
    live-boot \
    live-config \
    grub-pc \
    locales \
    squashfs-tools \
    sudo \
    git \
    curl \
    ansible \
    apache2-utils \
    cracklib-runtime \
    wget \
    zstd

# Configure locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Clean up apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Stage 4: Copy CyberPot repository
echo "Copying CyberPot repository into the chroot..."
mkdir -p "${CHROOT_DIR}/opt/cyberpot"
cp -r "${PROJECT_ROOT}/." "${CHROOT_DIR}/opt/cyberpot/"
chmod -R 755 "${CHROOT_DIR}/opt/cyberpot"

# Stage 5: Configure first-boot script
echo "Configuring first-boot script..."
# Copy the first-boot script and service file
cp "${CUSTOM_SCRIPTS_DIR}/cyberpot-first-boot.sh" "${CHROOT_DIR}/root/"
cp "${CUSTOM_SCRIPTS_DIR}/cyberpot-first-boot.service" "${CHROOT_DIR}/etc/systemd/system/"

# Make the first-boot script executable
chmod +x "${CHROOT_DIR}/root/cyberpot-first-boot.sh"

# Enable the first-boot service
chroot "${CHROOT_DIR}" systemctl enable cyberpot-first-boot.service

# Stage 6: Create the ISO image
echo "Creating the ISO image..."

# Unmount pseudo-filesystems
umount "${CHROOT_DIR}/dev"
umount "${CHROOT_DIR}/proc"
umount "${CHROOT_DIR}/sys"

# Create the ISO directory structure
mkdir -p "${ISO_DIR}/isolinux"
mkdir -p "${ISO_DIR}/live"

# Create the squashfs filesystem
mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -e boot

# Create isolinux.cfg
cat > "${ISO_DIR}/isolinux/isolinux.cfg" << EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
DEFAULT cyberpot-install

LABEL cyberpot-install
  MENU LABEL Automated CyberPot Install
  LINUX /live/vmlinuz
  INITRD /live/initrd.img
  APPEND boot=live components quiet preseed=/preseed.cfg
EOF

# Copy kernel and initrd
# Find the kernel and initrd files
KERNEL_VERSION=$(ls "${CHROOT_DIR}/boot/" | grep "vmlinuz-" | sed 's/vmlinuz-//')
cp "${CHROOT_DIR}/boot/vmlinuz-${KERNEL_VERSION}" "${ISO_DIR}/live/vmlinuz"
cp "${CHROOT_DIR}/boot/initrd.img-${KERNEL_VERSION}" "${ISO_DIR}/live/initrd.img"

# Copy isolinux binary
cp /usr/lib/ISOLINUX/isolinux.bin "${ISO_DIR}/isolinux/"
cp /usr/lib/syslinux/modules/bios/menu.c32 "${ISO_DIR}/isolinux/"

# Copy preseed file
cp preseed.cfg "${ISO_DIR}/preseed.cfg"

# Create the ISO
xorriso -as mkisofs \
  -r -J -joliet-long \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -o "${ISO_NAME}" \
  "${ISO_DIR}"

echo "--- ISO Build Complete ---"
echo "ISO image created at: ${ISO_NAME}"
