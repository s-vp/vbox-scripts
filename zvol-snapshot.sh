#!/usr/local/bin/bash
# This script creates a new ZFS ZVOL snapshot for an existing VM
# See the README.md file for general documentation
#
# This script takes one argument:
#  - the VM name, with an optional path prefix
#
# Caution!
# Never mix zfs snapshots and VirtualBox snapshots!
# The VM snapshot we use here is only to help with the VirtualBox clone command
# It is to be deleted and recreated every time we take a ZFS snapshot

### Constants
# The zfs mount point where are stored the ZVOLs
zvol_path='datapool/vmdisks/'
# TODO: add the possibilty to use other snapshot names
curr='Clean'
prev='Previous'
# VM snapshot to be cloned
tbc='ToBeCloned'
tbc_desc='Snapshot to be cloned with the vbox-zvol-snapshot.sh script.'

### User supplied variables
# $1: the full VM path, it can take subdirectories under $zvol_path
if [ -z $1 ]; then
    echo -e "\033[31mPlease provide a VM name/path to make a snapshot.\033[0m"
    exit 1
fi
VM_path=$1
VM=${VM_path/*\//}

echo -e "We're going to rotate the \033[38;5;12m@$curr\033[0m snapshot of \033[38;5;12m$VM\033[0m."
# Check VM exists, has ZVOL disks and is not running
VBoxManage showvminfo $VM > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to be existing.\033[0m"
    exit 1
fi
zfs list $zvol_path$VM_path > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m doesn't seem to have ZVOL disks at \033[38;5;12m$VM_path\033[0m"
    exit 1
fi
VBoxManage list runningvms | grep "\"$VM\"" > /dev/null
if [ $? -eq 0 ]; then
    echo -e "\033[31mThe VM \033[38;5;12m$VM\033[0;31m seems to be running, it is not recommended I take a ZVOL snapshot now.\033[0m"
    exit 1
fi

# If we have a VirtualBox snapshot, we probably shouldn't take a ZFS snapshot
VBoxManage snapshot $VM list | grep 'This machine does not have any snapshots' > /dev/null
if [ $? -ne 0 ]; then
    echo -e "\033[38;5;214mThe $VM VM has some snapshots, you shouldn't be mixing those with ZFS snapshots.\033[0m"
    echo -e "Better I quit here."
    exit 1
fi

# Rotate existing snapshot and take a new one
zfs list $zvol_path$VM_path@$prev > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
    # We have an existing $prev snapshot, we'll delete it
    zfs destroy $zvol_path$VM_path@$prev
    if [ $? -ne 0 ]; then
        echo -e "\033[38;5;214mSomething went wrong trying to destroy \033[38;5;12m$zvol_path$VM_path@$prev\033[0m"
        exit 1
    fi
fi
zfs rename $zvol_path$VM_path@$curr $zvol_path$VM_path@$prev
if [ $? -ne 0 ]; then
    echo -e "\033[31mSomething went wrong trying to rename \033[38;5;12m$zvol_path$VM_path@$curr to $zvol_path$VM_path@$prev\033[0m"
    echo "I quit!"
    exit 1
fi
zfs snapshot $zvol_path$VM_path@$curr
if [ $? -ne 0 ]; then
    echo -e "\033[31mSomething went wrong trying to create \033[38;5;12m$zvol_path$VM_path@$curr\033[0m"
else
    echo -e "We took a new snapshot of \033[1m$VM\033[0m at \033[38;5;12m$zvol_path$VM_path@$curr\033[0m and rotated the previous one at \033[38;5;12m$zvol_path$VM_path@$prev\033[0m"
fi

