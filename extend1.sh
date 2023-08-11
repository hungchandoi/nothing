#!/bin/bash
# Display disk space usage before resizing
echo "Disk space usage before resizing:"
df -h
# Get the name of the root volume group
ROOT_VG=$(df / | grep "/dev/mapper" | awk -F '/' '{print $4}' | awk -F '-' '{print $1}')
# Get the name of the new disk
NEW_DISK=$(lsblk -d -o NAME,TYPE | grep disk | grep -v sda | awk '{print $1}')
# Create a new partition on the new disk and format it as "Linux LVM"
echo -e "n\np\n1\n\n\nt\n8e\nw" | fdisk /dev/$NEW_DISK
partprobe /dev/$NEW_DISK
# Create physical volume on the new partition
pvcreate /dev/${NEW_DISK}1
# Extend volume group to include the new physical volume
vgextend $ROOT_VG /dev/${NEW_DISK}1
# Display volume group information
vgdisplay -v $ROOT_VG
# Extend the logical volume to use 100% of the free space
ROOT_LV_DEVICE=$(lvdisplay /dev/$ROOT_VG/root | grep "LV Path" | awk '{print $3}')
lvextend -l +100%FREE $ROOT_LV_DEVICE
xfs_growfs $ROOT_LV_DEVICE
# Display disk space usage after resizing
echo "Disk space usage after resizing:"
df -h
# Reboot the system
#reboot
