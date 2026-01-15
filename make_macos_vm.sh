#!/bin/bash

# Set TERM, DIALOGRC
export TERM=linux

# Let's define some global vars
myBACKTITLE="CyberPot - macOS VM Creator"
myPACKAGES="quickemu qemu-system-x86 unzip wget dialog"
myTMP="tmp_macos"
myCONF_FILE="macos_vm.conf"

# Got root?
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    sudo ./$0
    exit
fi

# Let's check if all dependencies are met
myINST=""
for myDEPS in $myPACKAGES;
do
  myOK=$(dpkg -s $myDEPS 2>/dev/null | grep ok | awk '{ print $3 }');
  if [ "$myOK" != "ok" ]
    then
      myINST=$(echo $myINST $myDEPS)
  fi
done

if [[ $myINST == *"quickemu"* ]]; then
    echo "quickemu not found, adding PPA and installing..."
    add-apt-repository ppa:flexiondotorg/quickemu -y
    apt-get update -y
    apt-get install quickemu -y
    # remove quickemu from myINST to avoid trying to install it again
    myINST=${myINST//quickemu/}
fi

if [ "$myINST" != "" ]
  then
    apt-get update -y
    for myDEPS in $myINST;
    do
      apt-get install $myDEPS -y
    done
fi

echo "Dependencies installed."

# Let's clean up at the end or if something goes wrong ...
function fuCLEANUP {
rm -rf $myTMP $myCONF_FILE
}
trap fuCLEANUP EXIT

echo "Setup for macOS VM creation is ready."
echo "Next steps: list macOS versions and let the user choose."
