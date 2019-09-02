#!/bin/bash

# -tor bin_name  
# -ton bin_name
# -rrtfs sourcr_bin_name edit_img_gz new_bin_name 
# -d  #to delete the middle files of replace the rootfs
# -e  #to get the bzImage and the rootfs.img.gz(include some 00 00 in the end)

# bzImage begin at 0x133120 end at \x1f\x8b\x08\x08
# rootfs.img.gz begin at  \x1f\x8b\x08\x08 end at \x0b\x01\x64\x00\x00

function help_message()
{
echo
echo "The help message of $0"
echo "---------------------------------"
echo "-help"
echo "	#Get the help message of options"
echo "-tor Source_bin "
echo "	#Edit the kernel command line to go to the rootfs "
echo "-ton Source_bin "
echo "	#Edit the kernel command line to startup normal "
echo "-rrtfs Source_bin Edit_rootfsImggz Target_bin "
echo "	#Replace the old rootfs.Img.gz in the Source_bin with the Edit_rootfsImggz to create Target_bin"
echo "-d"
echo "	#To delete the middle files of replace the rootf"
echo "-e Source_bin"
echo "	#To get the bzImage and the rootfs.img.gz(include some 00 00 in the end) from the Source_bin"
}

function gotorootfs()
{
Source_bin=$1

echo "Edit the kernel command line to go to the rootfs..."
if [ -n "$(strings $Source_bin |grep "quiet loglevel=0 auto")" ]; then
	sudo sed -i 's/quiet loglevel=0 auto/rdinit=\/bin\/sh       /' $Source_bin    #there are 7 space!
	echo "Replace done!"
elif [ -n "$(strings $Source_bin |grep "rdinit=/bin/sh       ")" ];then
	echo "Already have the rdinit=/bin/sh."
else
	echo "can't find \"quiet loglevel=0 auto\" or \"rdinit=/bin/sh       \",Please check the file!" 
	exit 1
fi
}

function gotonormal()
{
Source_bin=$1

echo "Edit the kernel command line to go to the normal..."
if [ -n "$(strings $Source_bin |grep "quiet loglevel=0 auto")" ]; then
	echo "Already have the quiet loglevel=0 auto."
elif [ -n "$(strings $Source_bin |grep "rdinit=/bin/sh       ")" ];then
	sudo sed -i 's/rdinit=\/bin\/sh       /quiet loglevel=0 auto/' $Source_bin
	echo "Replace done!"
else
	echo "can't find \"quiet loglevel=0 auto\" or \"rdinit=/bin/sh       \",Please check the file!" 
	exit 1
fi
}

function replacetherootfs()
{
echo "Replace the rootfs with a new one..."
Source_File=$1
Edit_ImgFile=$2
Target_File=$3

Loc_Img=$(binwalk -y 'gzip' $1 |grep "rootfs"|awk '{print $1}')
echo "Loc_Img=$Loc_Img"
Size_Before_Img=$Loc_Img
#Loc_Img is the offest in the source file,before it there are 3679104 bytes

Loc_0b01640000=$(binwalk -R "\x0b\x01\x64\x00\x00" $1 | grep 0x|awk '{print $1}'| tail -n 1)
echo "Loc_0b01640000=$Loc_0b01640000"
Size_Before_After=$Loc_0b01640000
#From the Loc_Img to the Loc_0b01640000 is the space we can edit.
#End_Img is the offest in the source file,before the After_Img there are End_Img+1 bytes

Size_SF=$(du -b $Source_File |cut -f 1)
Size_EI=$(du -b $Edit_ImgFile |cut -f 1)
echo "Size_SF=$Size_SF"
echo "Size_EI=$Size_EI"

let Size_Editable=$Size_Before_After-$Loc_Img
echo "Size_Editable=$Size_Editable"

let Size_Zero=$Size_Editable-$Size_EI
echo "Size_Zero=$Size_Zero"

if [ $Size_Zero -ge 0 ];then

	echo "injecting the edited img ......"

	sudo dd if=$Source_File of=Before_Img \
        	bs=$Size_Before_Img count=1 skip=0

	sudo dd if=$Source_File of=After_Img \
        	bs=$Size_Before_After  skip=1

	sudo dd if=/dev/zero of=Zero_Img \
        	bs=$Size_Zero count=1 skip=0

	sudo sh -c "cat Before_Img $2 Zero_Img After_Img > $Target_File"

	Size_TF=$(du -b $Target_File |cut -f 1)
	echo="Size_TF=$Size_TF"
	if [ $Size_TF -ne $Size_SF ];then
		echo "Target file size error,Please check"
	else
		echo "inject done!"
	fi

else
	echo "Error! $2 is too big to inject!"
	echo "You can try more powerful gzip to gzip the img and try angin."
	exit 1
fi
}

function delete_allmidfile()
{
if [ -f ./After_Img ];then 
sudo rm ./After_Img 
fi
if [ -f ./Before_Img ];then 
sudo rm ./Before_Img 
fi
if [ -f ./Zero_Img ];then 
sudo rm ./Zero_Img
fi
echo "Have deleted all middle files!"
}

function extract_bz_rt()
{

if [ -f ./bzImage ];then
echo "Warning:There is already a file named bzImage here!Please move or rename."
exit 1
fi
if [ -f ./rootfs.img.gz ];then
echo "Warning:There is already a file named rootfs.img.gz here!Please move or rename."
exit 1
fi

Source_File=$1

Loc_bzImage=133120
echo "Loc_bzImage=$Loc_bzImage"

Loc_Img=$(binwalk -y 'gzip' $1 |grep "rootfs"|awk '{print $1}')
echo "Loc_Img=$Loc_Img"

let Size_bzImage=$Loc_Img-$Loc_bzImage
echo "Size_bzImage=$Size_bzImage"

Loc_0b01640000=$(binwalk -R "\x0b\x01\x64\x00\x00" $1 | grep 0x|awk '{print $1}'| tail -n 1) #the last one
echo "Loc_0b01640000=$Loc_0b01640000"

if [ $Loc_bzImage -lt $Loc_Img -a $Loc_Img -lt $Loc_0b01640000 ];then
	sudo dd if=$Source_File of=head_rootfs \
        	bs=$Loc_0b01640000 count=1 skip=0

	sudo dd if=head_rootfs of=bzImage_rootfs \
        	bs=$Loc_bzImage  skip=1

	sudo dd if=bzImage_rootfs of=bzImage \
        	bs=$Size_bzImage count=1 skip=0
	
	sudo dd if=bzImage_rootfs of=rootfs.img.gz \
        	bs=$Size_bzImage skip=1
	
	sudo rm head_rootfs bzImage_rootfs
	
	echo
	if [ -n "$(file bzImage |grep "boot executable bzImage")" ];then
		echo "Extract the bzImage and rootfs.img.gz successfully!"
	else
		echo "Extract the bzImage has somethig Wrong!Please check file or the shell."
	fi
else
	echo "Locating the bzImage or the rootfs has something wrong,please check file or the shell."
	exit 1
fi
# bzImage begin at 0x133120 end at \x1f\x8b\x08\x08
# rootfs.img.gz begin at  \x1f\x8b\x08\x08 end at \x0b\x01\x64\x00\x00

}

while [ -n "$1" ]
do 
	case "$1" in
		-help) help_message;;
		-tor)   gotorootfs $2 ;shift ;;
		-ton)   gotonormal $2 ;shift ;;
		-rrtfs) replacetherootfs $2 $3 $4;shift 3;;
		-d) delete_allmidfile;;
		-e) extract_bz_rt $2;shift;;
		*) echo "$1 Wrong option!";exit 1;;
	esac
	shift
done

