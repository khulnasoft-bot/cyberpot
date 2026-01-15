#!/bin/bash

# This script runs on the first boot of the installed system.
# It runs the CyberPot installer and then disables itself.

# Exit on any error
set -e

echo "--- Starting CyberPot First Boot Installation ---"

# The install.sh script expects to be run as a non-root user.
# We will create a temporary user and run the installer as that user.
useradd -m -s /bin/bash tempuser
echo "tempuser:tempuser" | chpasswd
adduser tempuser sudo

# Run the installer as the temporary user
su - tempuser -c "bash /opt/cyberpot/install.sh" <<'EOF'
y
h
cyberpot
cyberpot
cyberpot
y
EOF

# Clean up the temporary user
userdel -r tempuser

echo "--- CyberPot First Boot Installation Finished ---"

# Disable this service so it doesn't run on subsequent boots
systemctl disable cyberpot-first-boot.service
rm /etc/systemd/system/cyberpot-first-boot.service
rm /root/cyberpot-first-boot.sh

echo "--- Rebooting in 30 seconds ---"
sleep 30
reboot
