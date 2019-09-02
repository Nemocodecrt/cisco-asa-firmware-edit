#!/bin/bash

# -dgz 
# -unpack
# -repack

function help_message()
{
echo
echo "The help message of $0"
echo "---------------------------------"
echo "-help"
echo "	#get the help message of options"
echo "-dgz Source_gz_file "
echo "	#decompress the gz_file,with gzip -d "
echo "-unpack Source_cpio_initrd Target_dir"
echo "	#unpack the Source_cpio_initrd to the Target_dir"
echo "-repack Source_dir Target_cpio_initrd"
echo "	#repack the Source_dir to Target_cpio_initrd"
echo "-gzip Source_cpio_initrd "
echo "	#gzip the Source_cpio_initrdi,default with gzip -7"
}

function ungzip_rootfs()
{
Source_gz_file=$1
echo "Decompressing the $Source_gz_file ..."
sudo gzip -d $Source_gz_file
echo "$Source_gz_file has been decompressed successfully!"
}

function unpack_cpio()
{
Source_cpio_initrd=$1
Target_dir=$2

if [ -n "$(file $Source_cpio_initrd|grep "cpio")" ];then
	echo  "unpacking the cpio-initrd ......"
	sudo mkdir $Target_dir
	cd $Target_dir
	sudo sh -c "cpio -idm < ../$Source_cpio_initrd "
	echo  "Unpack the cpio done."
else
	echo "Error :The Source file is not a cpio initrd! Please check!"
	exit 1
fi
}

function repack_cpio()
{
Source_dir=$1
Target_cpio_initrd=$2

cd $Source_dir
echo  "Repacking the cpio-initrd ......"
sudo sh -c "find .| cpio -H newc -o > ../$Target_cpio_initrd"
echo "Repack the cpio done."
}

function gzip_rootfs()
{
Source_cpio_initrd=$1
echo "Compressing the $Source_cpio_initrd ..."
sudo gzip -7 $Source_cpio_initrd
echo "$Source_cpio_initrd has been compressed successfully!"
}

while [ -n "$1" ]
do 
	case "$1" in
		-help)   help_message ;;
		-dgz)    ungzip_rootfs $2 ;shift;;
		-unpack) unpack_cpio $2 $3;shift 2;;
		-repack) repack_cpio $2 $3;shift 2;;
		-gzip)   gzip_rootfs $2 ;shift;; 
		*) echo "$1 is a wrong option!";exit 1;;
	esac
	shift
done

