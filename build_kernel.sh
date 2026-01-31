#!/bin/bash

# put the clang in the right path.
# put the clang-r346389c in the $(kernel directory)/../../prebuilts/clang/host/linux-x86 path

# Special Clean For Huawei Kernel.
if [ -d include/config ];
then
    echo "Find config,will remove it"
	rm -rf include/config
else
	echo "No Config,good."
fi

# Declare CLANG et LD_LIBRARY
export CLANG_PREBUILTS_PATH=/usr/
export GCC_PREBUILTS_PATH=/home/trijal/Builds/arm-gnu-toolchain-15.2.rel1-x86_64-aarch64-none-linux-gnu/

export CROSS_COMPILE=$GCC_PREBUILTS_PATH/bin/aarch64-none-linux-gnu-
export GCC_COLORS=auto
export ARCH=arm64

export PATH=$CLANG_PREBUILTS_PATH/bin/:$GCC_PREBUILTS_PATH/bin/:$PATH
export LD_LIBRARY_PATH=$CLANG_PREBUILTS_PATH/lib/:$CLANG_PREBUILTS_PATH/lib64/:$GCC_PREBUILTS_PATH/lib64/:$LD_LIBRARY_PATH

rm -rf cp out/arch/arm64/boot/Image.gz

echo "***Building kernel...***"

start_time=$(date +%Y.%m.%d-%I_%M)
start_time_sum=$(date +%s)

git submodule update --init --recursive

make ARCH=arm64 O=out CC="ccache clang" kirin970_defconfig ksun_sus.config nconfig
make ARCH=arm64 O=out CC="ccache clang" -j$(nproc --all) KCFLAGS="-fno-builtin-wcslen -Wno-error=incompatible-pointer-types -Wno-error=strict-prototypes -Wno-error=int-conversion -Wno-error=implicit-int"

end_time_sum=$(date +%s)
end_time=$(date +%Y.%m.%d-%I_%M)

# Durée
duration=$((end_time_sum - start_time_sum))
hours=$((duration / 3600))
minutes=$(( (duration % 3600) / 60 ))
seconds=$((duration % 60))

echo "Compilation time：${hours}:${minutes}:${seconds}"

if [ -f out/arch/arm64/boot/Image.gz ];
then
	echo "***Packing kernel...***"

	cp out/arch/arm64/boot/Image.gz Image.gz

	# Pack Permissive Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x00078000 --cmdline "loglevel=4 page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=permissive buildvariant=user" --tags_offset 0x37d88000 --kernel_offset 0x00008000 --second_offset 0x00e88000 --ramdisk_offset 0x37588000 --header_version 1 --os_version 10.0.0 --os_patch_level 2020-11 --output Kirin970_HOS2_permissive-${end_time}.img

	# Pack Enforcing Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x00078000 --cmdline "loglevel=4 page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=enforcing buildvariant=user" --tags_offset 0x37d88000 --kernel_offset 0x00008000 --second_offset 0x00e88000 --ramdisk_offset 0x37588000 --header_version 1 --os_version 10.0.0 --os_patch_level 2020-11 --output Kirin970_HOS2-${end_time}.img
# Now


	echo "***Sucessfully built kernel...***"
	echo " "
	exit 0
else
	echo " "
	echo "***Failed!***"
	exit 0
fi
