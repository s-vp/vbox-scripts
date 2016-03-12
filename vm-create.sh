#!/usr/local/bin/bash
#
# Clone an existing VM with disks on ZVOL
# See the README.md file for general documentation
#
# This script takes two arguments:
#  - the VM name to be cloned, with an optional path prefix
#  - the name of the new VM
#
# Caution!
# Never mix zfs snapshots and VirtualBox snapshots!
# 
# set -x 

# Set dfault config paraeters

if [ -z $2 ]; then os=OpenBSD_64 ; else os=$2 ; fi
if [ -z $3 ]; then cpus=1 ; else cpus=$3 ; fi
if [ -z $4 ]; then memory=256 ; else memory=$4 ; fi
if [ -z $5 ]; then zvolsize=7G ; else zvolsize=$5 ; fi

case  $os  in
                OpenBSD|openbsd|opebsd_32|OpenBSD_32|OpenBSD_i386)
                    installiso=/stage/distr/openbsd/STABLE/i386/rel/cd58.iso
					os_type=OpenBSD     
                    ;;
                OpenBSD_64|openbsd_64|opebsd_64|OpenBSD_amd64)
                    os_type=OpenBSD_64
                    installiso=/stage/distr/openbsd/STABLE/amd64/rel/cd58.iso
                    ;;
                FreeBSD_64|freebsd_64|FreeBSD_amd64)
                    os_type=FreeBSD_64
                    installiso=/stage/distr/freebsd/CURRENT/FreeBSD-11.0-CURRENT-amd64.raw
                    ;;
                Dragon_64|dragon_64|DragonflyBSD_64)
                    os_type=FreeBSD_64
                    installiso=/stage/distr/dragon/DragonFly-x86_64-LATEST-ISO.iso
                    ;;
                *)
          esac 


### Constants
zvol_root='/dev/zvol/'
# The zfs pool where are stored the ZVOLs
zfs_pool='datapool/vmdisks/'
hostnic=$(cat /etc/rc.conf |grep -v ^# |grep ifconfig |awk -F \_ '{ print $2 }'|awk -F \= '{ print $1 }' |tail -1 )

# ZFS snapshot names for a clean state and the previous clean state
curr='Clean'
prev='Previous'
# VirtualBox VM root
vbox_root='/vmdisks/'
# VM snapshot to be cloned
tbc='ToBeCloned'

### User supplied variables
# $1: the full VM path, it can take subdirectories under $zfs_pool

# $2: the full path for the new VM, it can take subdirectories under $zfs_pool
if [ -z $1 ]; then
    echo -e "\033[31mPlease provide a VM name/path for the new VM.\033[0m"
    exit 1
fi
new_VM_path=$1
new_VM=${new_VM_path/*\//}
new_VM_group='/'${new_VM_path%%\/*}

echo -e "We're going to create a new VM named \033[38;5;12m$new_VM\033[0m."

### Checks
# Check VM exists, has ZVOL disks and the $curr snapshot exists

# Check there's no existing VM with the new name
VBoxManage showvminfo $new_VM > /dev/null 2> /dev/null
ret=$?
if [ $ret -eq 0 ]; then
    echo -e "\033[31mThere is already a VM named \033[38;5;12m$new_VM\033[0m, please provide another name."
    exit 1
fi
if [ $ret -ne 1 ]; then
    echo -e "\033[38;5;214mThis was not the return code that I was expecting ($return) for \033[38;5;12m$new_VM\033[0m"
    echo "I continue anyway, but something might go wrong later."
fi

### Action
# 1. We clone the ZVOL and take a initial snapshot

zfs create -s -V ${zvolsize} ${zfs_pool}${new_VM_path}

if [ $? -ne 0 ]; then
    echo -e "\033[31mThere was a problem when cloning \033[38;5;12m$VM_path@$curr\033[31m to \033[38;5;12m$new_VM_path\033[0m"
    exit 1
fi


# 2. We take a snapshot and clone the VM, then remove any associated disk
# VBoxManage snapshot $VM take ${tbc}
# if [ $? -ne 0 ]; then
#    echo -e "\033[38;5;214mSomething went wrong trying to take a \033[38;5;12m${tbc} snapshot on $VM\033[0m"
#    echo -e "The VM was not cloned, but its disk were cloned.  You might need to delete these manually."
#    exit 1
#fi
# VBoxManage clonevm $VM --snapshot $tbc --mode machine --basefolder ${vbox_root} --options link --name $new_VM  --register
# vmdk_snap=`VBoxManage list hdds | awk "/\/${new_VM}\/Snapshots\// {print \\$2}"`
# VBoxManage storageattach $new_VM --storagectl "SATA" --port 0 --medium none
# VBoxManage closemedium disk "$vmdk_snap" --delete

# 2 recreating VM, NOT using vmclone  

VBoxManage createvm --name ${new_VM} --ostype $os_type --register --basefolder ${vbox_root}
VBoxManage modifyvm ${new_VM} --cpus ${cpus} --cpuhotplug on --ioapic on --pae on --hpet on --hwvirtex on  
VBoxManage modifyvm ${new_VM} --memory ${memory} --pagefusion on --nestedpaging on --largepages on
VBoxManage modifyvm ${new_VM} --boot1 disk --boot2 dvd --snapshotfolder /vmsnapshots/${new_VM_path} --nic1 nat --nictype1 virtio --nic2 bridged --nictype2 virtio  --bridgeadapter2 "${hostnic}"



# 3. We create a new VMDK
## VBoxManage storageattach $new_VM --storagectl "SATA" --port 0 --medium none
#
VBoxManage internalcommands createrawvmdk -filename ${vbox_root}${new_VM_path}/${new_VM}.vmdk -rawdisk ${zvol_root}${zfs_pool}${new_VM_path}

# 4. We attach the VMDK to the newly created VM and we can delete the VM snapshot

#VBoxManage storagectl ${new_VM} --name "SAS" --add sas --hostiocache off
#VBoxManage storageattach $new_VM --storagectl "SAS" --port 0 --type hdd --medium ${vbox_root}${new_VM_path}/${new_VM}.vmdk


VBoxManage storagectl ${new_VM} --name "SCSI" --add scsi --hostiocache off
VBoxManage storageattach $new_VM --storagectl "SCSI" --port 0 --type hdd --medium ${vbox_root}${new_VM_path}/${new_VM}.vmdk

VBoxManage storagectl $new_VM --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach $new_VM --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $installiso


if [ $? -ne 0 ]; then
    echo -e "\033[38;5;214mSomething went wrong, check the logs\033[0m"
fi

echo -e "\033[38;5;12m${new_VM}\033[0m was created with its disk as \033[38;5;12m${zvol_root}${zfs_pool}${new_VM_path}\033[0m"

