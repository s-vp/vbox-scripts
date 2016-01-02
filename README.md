============================================================================================
set of scripts for VirtualBox provisioning and cloning on top of ZFS ZVOLs 
============================================================================================


vm-destroy.sh 
---------------------------------------------------------------------------------
  

destroys specisfied VM from Virtualbox repository and underlaying ZFS Volume  
accepts vm name as an input parameter 


*** 


vm-create.sh
---------------------------------------------------------------------------------

creates new VM with given pramaters

accepts vm name as a first input argument (mandatory) 
other optional arguments (in a given order): 
* ostype (default: OpenBSD_64)
* number of vcpu (default: 1)
* amount of RAM (in MB) (default: 256)
* size of ZFS Volume (default value is 7G)


NOTE: paths to the zvol hardcoded into the script custom-tailoring and renaming may be required


*** 



vm-clone.sh 
---------------------------------------------------------------------------------
  
cloning VM and underlying ZVOL with a given parameter: 

accepts SOURCE and TAREEGT vm names as a first and second input arguments (mandatory) 
other optional arguments (in a given order): 
* number of vcpu for TARGET VM (default: 1)
* amount of RAM (in MB) for TARGET (default: 256)


NOTE: paths to the zvol hardcoded into the script custom-tailoring and renaming may be required. 


*** 

