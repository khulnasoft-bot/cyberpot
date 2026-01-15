#!/bin/bash

# Supported distributions
mySUPPORTED_DISTRIBUTIONS=("AlmaLinux" "Debian GNU/Linux" "Fedora Linux" "openSUSE Tumbleweed" "Raspbian GNU/Linux" "Rocky Linux" "Ubuntu")

# Detect current distribution
myCURRENT_DISTRIBUTION=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')

# Function to check if distribution is supported
check_distribution() {
    if [[ ! " ${mySUPPORTED_DISTRIBUTIONS[@]} " =~ " ${myCURRENT_DISTRIBUTION} " ]]; then
        echo "### Only the following distributions are supported: AlmaLinux, Fedora, Debian, openSUSE Tumbleweed, Rocky Linux and Ubuntu."
        echo "### Please follow the CyberPot documentation on how to run CyberPot on macOS, Windows and other currently unsupported platforms."
        echo
        exit 1
    fi
}
