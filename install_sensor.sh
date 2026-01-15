#!/usr/bin/env bash

myINSTALL_NOTIFICATION="### Now installing required packages ..."
myUSER=$(whoami)
myCYBERPOT_CONF_FILE=".env"

# Source package definitions
if [ -f "installer/lib/packages.sh" ]; then
    source installer/lib/packages.sh
else
    echo "Error: installer/lib/packages.sh not found."
    exit 1
fi

myINSTALLER=$(cat << "EOF"
   ______      __              ____        __ 
  / ____/_  __/ /_  ___  _____/ __ \____  / /_
 / /   / / / / __ \/ _ \/ ___/ /_/ / __ \/ __/
/ /___/ /_/ / /_/ /  __/ /  / ____/ /_/ / /_  
\____/\__, /_.___/\___/_/  /_/    \____/\__/  
     /____/                                   
EOF
)

# Check if running on a supported distribution
if [ -f "installer/lib/distros.sh" ]; then
    source installer/lib/distros.sh
    check_distribution
else
    echo "Error: installer/lib/distros.sh not found."
    exit 1
fi

echo "$myINSTALLER"
echo "### SENSOR EDITION"
echo
echo "### This script will install CyberPot in SENSOR mode."
echo

# Collect Hive Settings early
read -p "### Enter your HIVE IP or FQDN: " myHIVE_IP
read -p "### Enter your HIVE Username: " myHIVE_USER_NAME
read -s -p "### Enter your HIVE Password: " myHIVE_PASS
echo
myHIVE_USER_ENC_B64=$(echo -n "${myHIVE_USER_NAME}:${myHIVE_PASS}" | base64 -w0)

# Install packages based on the distribution
case ${myCURRENT_DISTRIBUTION} in
  "Fedora Linux")
    sudo dnf -y --refresh install ${myPACKAGES_FEDORA}
    ;;
  "Debian GNU/Linux"|"Raspbian GNU/Linux"|"Ubuntu")
    sudo apt update && sudo NEEDRESTART_SUSPEND=1 apt install -y ${myPACKAGES_DEBIAN}
    ;;
esac

# Run Ansible for basic system prep
if [ -f "installer/install/cyberpot.yml" ] || [ -f "cyberpot.yml" ]; then
    myPLAYBOOK=${ANSIBLE_CYBERPOT_PLAYBOOK:-"installer/install/cyberpot.yml"}
    [ ! -f "$myPLAYBOOK" ] && myPLAYBOOK="cyberpot.yml"
    sudo ansible-playbook ${myPLAYBOOK} -i 127.0.0.1, -c local --tags "$(echo ${myCURRENT_DISTRIBUTION} | cut -d " " -f 1)" --become
fi

# Set SENSOR mode
echo "### Configuring SENSOR mode..."
cp compose/sensor.yml docker-compose.yml
sed -i "s|^CYBERPOT_TYPE=.*|CYBERPOT_TYPE=SENSOR|" ${myCYBERPOT_CONF_FILE}
sed -i "s|^CYBERPOT_HIVE_IP=.*|CYBERPOT_HIVE_IP=${myHIVE_IP}|" ${myCYBERPOT_CONF_FILE}
sed -i "s|^CYBERPOT_HIVE_USER=.*|CYBERPOT_HIVE_USER=${myHIVE_USER_ENC_B64}|" ${myCYBERPOT_CONF_FILE}

# Pull sensor-only images
echo "### Pulling SENSOR images..."
sudo docker compose pull

echo "### SENSOR installation complete!"
echo "### Logs will be forwarded to Hive: ${myHIVE_IP}"
