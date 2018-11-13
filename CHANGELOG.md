## 7.0.8 (November 13, 2018)
FEATURES:
  - Write the PeerOs IP address to generated file (_IP_PEER).

## 7.0.7 (November 07, 2018)

BUG FIXES:
  - [Parallels] Fixed bug with disability of creating virtual disk. #135
  - Fixed bug with white space in home directory path results in VM storage growth script failures. #129

FEATURES:  
  - [configuration] Implemented LIBVIRT_POOL configuration parameter. #127
  - [configuration] Implemented APT_PROXY_URL configuration parameter

## 7.0.6 (October 17, 2018)

BUG FIXES:
  - Blueprint provisioning via bazaar mode fixed
  - Fixed .vagrant folder is being generated in several places. (edited)

FEATURES:  
  - [configuration] Added `shared` as a value in addition to `private` and `public` in the *SUBUTAI_SCOPE* configuration parameter
  - [configuration] Implemented SUBUTAI_DESKTOP configuration parameter
  - [Hyper-V] Write peer ip address to generated file

## 7.0.4 (June 26, 2018)

BUG FIXES:
  - Blueprint provisioning template not found fixed 

FEATURES: 
  - Added new bridge configuration property by specific hypervisor
  - User configuration added new keys:
      -  SUBUTAI_DISK
      -  BRIDGE_VIRTUALBOX
      -  BRIDGE_PARALLELS
      -  BRIDGE_VMWARE
      -  BRIDGE_KVM
      -  BRIDGE_HYPERV 

## 7.0.3 (May 30, 2018)
  
BUG FIXES:
  - [hyperv, vmware_desktop] fixed delete virtual disk file after destroy VM
  - user configuration validation 

## 7.0.2 (May 22, 2018)

BUG FIXES:
  - Fixed validation url  

## 7.0.1 (May 21, 2018)

FEATURES:
  - Support HyperV hypervisor
  - Improved validation (user configuration)  

## 7.0.0 (May 9, 2018) 

FEATURES:
  - Support Vmware desktop and Parallels hypervisor    
  - Auto registration PeerOs to Bazaar
  - User configuration new keys added (BAZAAR_NO_AUTO)  

## 1.1.7 (April 7, 2018) 
  
BUG FIXES:
  - null port forward value fixed   

FEATURES:
  - User configuration new keys added (LIBVIRT_USER, LIBVIRT_HOST, LIBVIRT_PORT, LIBVIRT_MACVTAP, LIBVIRT_NO_BRIDGE)  

## 1.1.6 (April 2, 2018)

BUG FIXES:
  - User configuration values case sensitive fixed  

## 1.1.5 (March 31, 2018) 

FEATURES:
  - [Command] `deregister` command added (For unregistering the PeerOS from Bazaar)  

## 1.1.4 (March 30, 2018)

FEATURES: 
  - Libvirt disk size function added
  - Cdn verfify certificate removed  

## 1.1.3 (March 23, 2018)

BUG FIXES:

  - [Linux] arp command replaces with ip
  - Long running ansible playbook error fixed

FEATURES:

  - VM Disk Path variable added to conf file (SUBUTAI_DISK_PATH)  

## 1.1.2 (March 15, 2018)

BUG FIXES:

  - [Windows] Blueprint provisioning run first vagrant up     

## 1.1.1 (March 15, 2018)

BUG FIXES:

  - Blueprint provisioning check for ready PeerOS 

## 1.1.0 (March 13, 2018)

FEATURES:

  - Blueprint provisioning in two modes bazaar and peer
  - Open command PeerOS in browser  