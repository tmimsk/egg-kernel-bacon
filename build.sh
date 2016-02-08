#!/bin/bash
#
# Egg-CM build script
#
clear

MODE="$1"
if [ ! -z $MODE ]; then
    if [ "$MODE" == "r" ]; then
        echo "This is a stable release build!"
        export LOCALVERSION="-Egg-Stable"
    fi
else
    echo "This is a nightly build!"
    export LOCALVERSION="-Egg-Nightly"
fi

# Resources
THREAD="-j2"
KERNEL="zImage"
DTBIMAGE="dtb"
DEFCONFIG="cyanogenmod_bacon_defconfig"

# Kernel Details
VARIANT=$(date +"%Y%m%d")
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=${HOME}/secret/chamber/cortex_a15/bin/arm-eabi-

# Paths
KERNEL_DIR="${HOME}/secret/one-cm"
ANYKERNEL_DIR="${HOME}/secret/chamber/anykernel"
PATCH_DIR="${HOME}/secret/chamber/anykernel/patch"
ZIP_MOVE_STABLE="${HOME}/secret/out/stable"
ZIP_MOVE_NIGHTLY="${HOME}/secret/out/nightly"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions
function clean_all {
		cd $ANYKERNEL_DIR
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
        cd $ANYKERNEL_DIR
        git checkout egg-cm-13.0-CM
        cd $KERNEL_DIR
}

function make_dtb {
		$ANYKERNEL_DIR/tools/dtbToolCM -2 -o $ANYKERNEL_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_zip {
		cp -vr $ZIMAGE_DIR/$KERNEL $ANYKERNEL_DIR
		cd $ANYKERNEL_DIR
        if [ ! -z $MODE ]; then
            if [ "$MODE" == "r" ]; then
	            zip -r9 egg-cm-13.0-stable-$VARIANT.zip *
	            mv egg-cm-13.0-stable-$VARIANT.zip $ZIP_MOVE_STABLE
            fi
		else
		    zip -r9 egg-cm-13.0-nightly-$VARIANT.zip *
		    mv egg-cm-13.0-nightly-$VARIANT.zip $ZIP_MOVE_NIGHTLY
		fi
		cd $KERNEL_DIR
}

echo "Egg Kernel Creation Script:"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

DATE_START=$(date +"%s")

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		if [ -f $ZIMAGE_DIR/$KERNEL ];
		then
			make_dtb
			make_zip
		else
			echo
			echo "Kernel build failed."
			echo
		fi
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
