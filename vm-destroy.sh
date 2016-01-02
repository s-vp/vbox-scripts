#!/usr/local/bin/bash
#
# Destroy an existing VM and its ZVOL
# See the README.md file for general documentation
#
# This script takes one argument:
#  - the VM name, with an optional path prefix


### Constants
zvol_root='/dev/zvol/'
# The zfs pool where are stored the ZVOLs
zfs_pool='datapool/vmdisks/'
# ZFS snapshot names for a clean state and the previous clean state
curr='Clean'
prev='Previous'


### User supplied variables
# $1: the full VM path, it can take subdirectories under $zvol_path
if [ -z $1 ]; then
    echo -e "\033[31mPlease provide a VM name/path to destroy.\033[0m"
    exit 1
fi
VM_path=$1
VM=${VM_path/*\//}

### Checks
# Check VM exists and has ZVOL disks
VBoxManage showvminfo $VM > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to be existing.\033[0m"
    exit 1
fi
zfs list $zfs_pool$VM_path > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to have a ZVOL disk at \033[38;5;12m$VM_path\033[0m"
    exit 1
fi

### Ask for confirmation
#
echo -e "We're going to delete \033[38;5;12m$VM\033[0m and destroy all of its ZVOL under \033[38;5;12m$VM_path\033[0m. Here is a simulation:"
zfs destroy -rnv $zfs_pool$VM_path
echo -e "\033[1mIs that ok?\033[0m"
unset ANSWER
read -p "(y/N) " -n 1 ANSWER
echo
if [[ "${ANSWER:=n}" == "n" || "${ANSWER:=N}" == "N" ]]; then
    echo "Ok, I quit"
    exit
fi

### Take action
# Delete VM
VBoxManage unregistervm $VM --delete
if [ $? -ne 0 ]; then
    echo -e "\033[31mThere was an error trying to delete the VM \033[38;5;12m$VM\033[0m."
    echo -e "It's better I stop here."
    exit 1
fi

# Destroy ZVOL and associated snapshots
zfs destroy -rv $zfs_pool$VM_path
if [ $? -eq 0 ]; then
    echo -e "\033[38;5;12m${VM}\033[0m was deleted and its disk is destroyed."
else
    echo -e "\033[31mSomething went wrong trying to destroy \033[38;5;12m$zfs_pool$VM_path\033[0m"
    echo -e "But the VM \033[38;5;12m$VM\033[0;31m is deleted."
    echo -e "Check the error messages above."
fi

