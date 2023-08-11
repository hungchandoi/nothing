#!/bin/bash

# Check if the script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Check if the device /dev/sda exists
if [ ! -e "/dev/sda" ]; then
    echo "Device /dev/sda does not exist"
    exit 1
fi

# Check the current status of the root partition
root_partition=$(df -h / | awk 'NR==2{print $1}')
echo "Current root partition: $root_partition"

# Run fdisk to create a new partition
echo "Creating a new partition on /dev/sda..."
fdisk /dev/sda <<EOF
n
p
3


t
3
8e
w
EOF

# Inform the kernel about the new partition
partprobe /dev/sda

# Wait a few seconds for the kernel to update
sleep 5

# Create a physical volume on the new partition
pvcreate /dev/sda3

# Extend the volume group to include the new physical volume
vgextend centos /dev/sda3

# Display the volume group information
vgdisplay centos

# Extend the root logical volume
lvextend -l +100%FREE /dev/centos/root

# Resize the filesystem on the root logical volume
resize2fs /dev/centos/root

xfs_growfs /dev/centos/root
df -h

echo "Root partition extended successfully."
