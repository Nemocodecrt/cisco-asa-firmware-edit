#!/bin/bash

#-mt image/qcow2 num_p
#-rbin qcow2 bin
#-tty qcow2
#-notty qcow2

function help_message()
{
echo
echo "The help message of $0"
echo "---------------------------------"
echo "-help"
echo "	#get the help message of options"
echo "-mt Image/qcow2 num_p "
echo "	#mount the Image/qcow2's num_p partition"
echo "-rbin Source_qcow2 Source_bin"
echo "	#replace the bin file in Source_qcow2 with the Source_bin"
echo "-tty Source_qcow2"
echo "	#edit the Source_qcow2 to make the lina use ttyS0"
echo "-notty Source_qcow2"
echo "	#edit the Source_qcow2 to make the lina don't use ttyS0"
}

function mount_qcow2()
{
FILE_IMG=$1
NUM_P=$2
#NUM_P is the number of partitions of img

if [ ! -d /mnt/img ];then
	sudo mkdir /mnt/img
	echo "/mnt/img has been created."
else
	sudo modprobe nbd
	sudo umount /mnt/img
	sudo qemu-nbd --disconnect /dev/nbd0
	echo "connected $FILE_IMG to the /dev/nbd0. "
	sudo qemu-nbd --connect=/dev/nbd0 $FILE_IMG
	#sudo fdisk /dev/nbd0 -l
	echo "mount /dev/nbd0p$NUM_P /mnt/img"
	sudo mount /dev/nbd0p$NUM_P /mnt/img

fi
}

function mount_qcow2_tree()
{
if [ $# -lt 2 ];then
        echo "Warning: Maybe miss the number of partition!"
        echo "Please try again with the number of partitions!"
	exit 1
else
	mount_qcow2 $1 $2
	echo
	sudo fdisk /dev/nbd0 -l
	echo
	sudo tree /mnt/img
fi
}

function replace_bin()
{
Source_qcow2=$1
Source_bin=$2
mount_qcow2 $Source_qcow2 1
sudo rm /mnt/img/asa*bin
echo
echo "Coping,Please wait a minute ......"
sudo cp $Source_bin /mnt/img
echo
sudo tree /mnt/img
echo
echo "$Source_bin has been put in $Source_qcow2 successfully!"
}

function usettyS0()
{
Source_qcow2=$1
mount_qcow2 $Source_qcow2 2
if [ -f /mnt/img/use_ttyS0 ];then
	echo
	echo "use_ttyS0 is in p2 of $Source_qcow2 already."
else
	sudo touch /mnt/img/use_ttyS0
	sudo tree -d /mnt/img
	echo
	echo "use_ttyS0 has been created in p2 of $Source_qcow2!"
fi
echo "The lina will use the ttyS0."
}

function no_usettyS0()
{
Source_qcow2=$1
mount_qcow2 $Source_qcow2 2
if [ ! -f /mnt/img/use_ttyS0 ];then
	echo
	echo "use_ttyS0 isn't in p2 of $Source_qcow2 already."
else
	sudo rm /mnt/img/use_ttyS0
	sudo tree -d /mnt/img
	echo
	echo "use_ttyS0 has been deleted!"
fi
}

while [ -n "$1" ]
do
	case "$1" in
		-help) help_message ;;
		-mt) mount_qcow2_tree $2 $3;shift 2;;
		-rbin) replace_bin $2 $3;shift 2;;
		-tty) usettyS0 $2;shift;;
		-notty) no_usettyS0 $2;shift;;
		*) echo "$1 is a wrong option.";exit 1;;
	esac
	shift
done
