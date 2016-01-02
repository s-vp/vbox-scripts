============================================================================================
bash scripts for VirtualBox VMs provisioning and cloning on top of ZFS Volumes (ZVOLs) 
============================================================================================


vm-destroy.sh 
---------------------------------------------------------------------------------
  

* delete specisfied VM from Virtualbox repository and 
* destroy underlaying ZFS Volume

pass VM name as an input parameter 


*** 


vm-create.sh
---------------------------------------------------------------------------------

* creates new VM with given pramaters

accepts vm name as a first input argument (mandatory) 
other optional arguments (in a given order): 
* ostype (default: OpenBSD_64)
* number of vcpu (default: 1)
* amount of RAM (in MB) (default: 256)
* size of ZFS Volume (default value is 7G)


NOTE: paths to the zvol hardcoded into the script custom-tailoring and renaming may be required


*** 


zvol-snapshot.sh
---------------------------------------------------------------------------------

* check for a VirtualBox snapshots for a given VM name (mandatory argument) and if VM is not running
* then create zfs snapshot for a VM's zfs volume 

snapshots naming convention: 

* new snapshot will be named ${PATH_TO_ZVOL}@Clean
* any existsing ZFS snapshot will be renamed to ${PATH_TO_ZVOL}@Previous

NOTE: paths to the zvol hardcoded into the script custom-tailoring and renaming may be required


***


vm-clone.sh 
---------------------------------------------------------------------------------
  
* clone VM and underlying ZVOL with a given parameter: 

accepts SOURCE and TARGET vm names as a first and second input arguments (mandatory) 
other optional arguments (in a given order): 
* number of vcpu for TARGET VM (default: 1)
* amount of RAM (in MB) for TARGET (default: 256)


NOTE: paths to the zvol hardcoded into the script custom-tailoring and renaming may be required. 


*** 

