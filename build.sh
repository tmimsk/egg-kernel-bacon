#!/bin/bash
#
# Egg-CAF Falcon build script
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
DEVICE="bacon"

# Kernel Details
VARIANT=$(date +"%Y%m%d")
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=${HOME}/linaroa15/bin/arm-cortex_a15-linux-gnueabihf-

# Paths
KERNEL_DIR="${HOME}/kernel/bacon"
ANYKERNEL_DIR="${HOME}/kernel/anykernel"
ZIP_MOVE_STABLE="${HOME}/kernel/out/$DEVICE/stable"
ZIP_MOVE_NIGHTLY="${HOME}/kernel/out/$DEVICE/nightly"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions
function clean_all {
		cd $ANYKERNEL_DIR
		git checkout bacon
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make CONFIG_DEBUG_SECTION_MISMATCH=y $THREAD
        cd $ANYKERNEL_DIR
        git checkout falcon
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
	            zip -r9 egg-caf-$DEVICE-stable-$VARIANT.zip *
	            mv egg-caf-$DEVICE-stable-$VARIANT.zip $ZIP_MOVE_STABLE
            fi
		else
		    zip -r9 egg-caf-$DEVICE-nightly-$VARIANT.zip *
		    mv egg-caf-$DEVICE-nightly-$VARIANT.zip $ZIP_MOVE_NIGHTLY
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

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		DATE_START=$(date +"%s")
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
		DATE_START=$(date +"%s")
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
