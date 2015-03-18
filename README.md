# thinboot
a linux iscsi-based thinclient environment, the environment is build on the top of ubunti 14.04 server and puppet

## server
* Disks (LVM managed with puppet)
* iSCSI (tgt)
* DHCP DNS TFT (dnsmasq)
* PXE (iPXE / sanboot)

## thinclient
* PXE-boot (loads iPXE)
* pressed-installation (if boot from iSCSI-MBR fails)
* mutipath (for the iSCSI target)
* aufs (make root-filesystem readonly)
