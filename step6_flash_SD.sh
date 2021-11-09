#!/bin/bash

# Create a base custome image for jetson nano
# vuquangtrong@gmail.com
#
# step 6: flash SD card

##########
echo "Check root permission"

if [ "x$(whoami)" != "xroot" ]; then
	echo "This script requires root privilege!!!"
	exit 1
fi

##########
echo "Get environment"

source ./step0_env.sh

##########
echo "Set script options"

set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

##########
echo "Check that $1 is a block device"

if [ ! -b $1 ] || [ "$(lsblk | grep -w $(basename $1) | awk '{print $6}')" != "disk" ]; then
	echo "$1 is not a block device!!!"
	exit 1
fi

##########
IMAGE=${WORK_DIR}/Linux_for_Tegra/tools/${JETSON_BOARD}_${RELEASE}_${JETSON_PLAT}_${JETSON_REL}_${JETSON_DESKTOP}.img
echo "Using ${IMAGE}"


##########
if [ "$(mount | grep $1)" ]; then
    echo "Unmount $1"
	for mount_point in $(mount | grep $1 | awk '{ print $1}'); do
		sudo umount $mount_point > /dev/null
	done
fi

##########
printf "Flash $1"
dd if=${IMAGE} of=$1 bs=4M conv=fsync status=progress

##########
echo "Extend the partition"

partprobe $1 &> /dev/null
sgdisk -e $1 > /dev/null

end_sector=$(sgdisk -p $1 |  grep -i "Total free space is" | awk '{ print $5 }')
start_sector=$(sgdisk -i 1 $1 | grep "First sector" | awk '{print $3}')

echo "start_sector = ${start_sector}"
echo "end_sector = ${end_sector}"

sgdisk -d 1 $1 > /dev/null
sgdisk -n 1:$start:$end $1 /dev/null
sgdisk -c 1:APP $1 > /dev/null

##########
echo "Extend the filesystem"

e2fsck -fp $1"p1" > /dev/null
resize2fs $1"p1" > /dev/null
sync

echo "DONE!"
