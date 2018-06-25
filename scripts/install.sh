#!/bin/bash
# Shell script to install a raspbian image to an (Micro-)SD card.

usage ()
{
	echo "You must provide both the Raspbian image file and the device to write this image to."
	echo "Raspbian OS images can be downloaded from https://www.raspberrypi.org/downloads/raspbian/."
	echo ""
	echo "  Usage: `basename $0` -i <image> -d <device>"
    echo "    e.g. `basename $0` -i 2018-04-18-raspbian-stretch.img -d /dev/sdb"
    exit 1
}

while getopts "i:d:h" opt; do
	case "${opt}" in
		i)
			image=$OPTARG
			;;
		d)
			device=$OPTARG
			;;
		*)
			usage
			;;
	esac
done

errors=0
# Check if all required options have been set
if [ -z "${image}" ]; then echo "Image file not specified!"; errors=$((errors + 1)); fi
if [ -z "${device}" ]; then echo "Device not specified!"; errors=$((errors + 1)); fi
if [ ${errors} -gt 0 ]; then echo ""; usage; fi


# Sanity checks
if [ ! -f "${image}" ]; then
	echo "Can not find image file ${image}"
	exit 2
fi
if [ ! -r "${image}" ]; then
	echo "Can not read image file ${image}"
	exit 3
fi

if [ ! -b "${device}" ]; then
	echo "Block device ${device} does not exist"
	exit 4
fi

# Ask if user wants to continue
echo "WARNING: Overwriting device ${device}:"
echo "======================================"
if [ "Darwin" = "`uname`" ]; then
	if [ ! -z "`which diskutil`" ]; then
		diskutil list ${device}
	fi
else
	sudo fdisk -l ${device}
fi

echo "WARNING: All data on ${device} will be deleted!"
echo ""
echo $'Press any key to continue or Ctrl+C to exit...'
read -rs -n1
echo ""
echo "The sudo password is needed to write the image to the device."
sudo echo ""


echo "Writing image to ${device} ..."
if [ ! -z "`which pv`" ]; then
	dd if=${image} | pv --progress --timer --eta --bytes --rate --size `wc -c ${image} | awk '{ print $1 }'` | sudo dd of=${device} bs=8192
else
	sudo dd if=${image} of=${device} bs=8192
fi
if [ $? -ne 0 ]; then echo "An error has occurred. Aborting."; exit $?; fi


echo "Determining boot partition ..."
if [ "Darwin" = "`uname`" ]; then
	bootpartition="${device}s1"
else
	bootpartition="${device}1"
fi
echo "Boot partition: ${bootpartition}"


TMPDIR=`mktemp -d`
echo "Created temporary directory ${TMPDIR}"

echo "Mounting boot partition ..."
sudo mount ${bootpartition} ${TMPDIR}
if [ $? -ne 0 ]; then echo "An error has occurred. Aborting."; exit $?; fi

echo "Activating SSH server ..."
touch ${TMPDIR}/ssh
if [ $? -ne 0 ]; then echo "An error has occurred. Aborting."; exit $?; fi

echo "Unounting boot partition ..."
sudo umount ${TMPDIR}
if [ $? -ne 0 ]; then echo "An error has occurred. Aborting."; exit $?; fi

echo "Deleting ${TMPDIR}"
rm -r ${TMPDIR}
if [ $? -ne 0 ]; then echo "An error has occurred. Aborting."; exit $?; fi

echo ""
echo "Installation finished."
echo "Please put the SD card to your Raspberry Pi, connect it to a network"
echo "(using a LAN cable) and power it on. Once the device has booted, you"
echo "can proceed and complete the following steps to get your AirPlay speakers"
echo "available in your network:"
echo ""
echo "1. You need to create a user on the Raspberry Pi that will be used to"
echo "   log in and run the proceeding installation tasks. To create this user"
echo "   simply run (make sure that there is a comma (,) after the IP address!):"
echo "     $ ansible-playbook -u pi -k -i <ip>, -k playbooks/createuser.yml"
echo ""
echo "2. Install and configure the software on the Raspberry Pi:"
echo "     $ ansible-playbook -i <ip>, -k playbooks/postinstall.yml"
echo ""
exit

# eof