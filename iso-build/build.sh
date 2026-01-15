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


# Check for required tools
for tool in debootstrap xorriso mksquashfs; do
    if ! command_exists "$tool"; then
        echo "Installing required tool: $tool"
        apt-get update
        apt-get install -y --no-install-recommends debootstrap xorriso squashfs-tools
    fi
done

# Clean up previous builds
echo "Cleaning up previous builds..."
rm -rf "${BUILD_DIR}"

# Create build directories
echo "Creating build directories..."
mkdir -p "${CHROOT_DIR}" "${ISO_DIR}/isolinux" "${ISO_DIR}/live" "${CUSTOM_SCRIPTS_DIR}"

# Stage 1: Create a minimal Debian system
echo "Debootstrapping Debian ${DISTRO}..."
debootstrap --arch amd64 --variant=minbase "${DISTRO}" "${CHROOT_DIR}" "${MIRROR}"

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
    grub-pc \
    locales \
    squashfs-tools \
    sudo \
    git \
    curl \
    ansible \
    apache2-utils \
    cracklib-runtime \
    wget

# Configure locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Clean up apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# Stage 4: Copy CyberPot repository
echo "Copying CyberPot repository into the chroot..."
cp -r "${PROJECT_ROOT}" "${CHROOT_DIR}/root/cyberpot"

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
