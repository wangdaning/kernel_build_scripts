#!/bin/bash
set -e

# Check if 'builds' folder exists, create it if not
if [ ! -d "./builds" ]; then
    echo "'builds' folder not found. Creating it..."
    mkdir -p ./builds
else
    echo "'builds' folder already exists removing it."
    rm -rf ./builds
    mkdir -p ./builds
fi

# Create the root folder with the current date and time (AM/PM)
cd ./builds
ROOT_DIR="Shusky-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.19
git clone https://github.com/TheWildJames/kernel_patches.git

# Get the kernel
echo "Get the kernel..."
mkdir shusky
cd ./shusky
repo init -u https://android.googlesource.com/kernel/manifest  --depth=1 -b android-gs-shusky-6.1-android15-qpr2-beta
repo sync --current-branch --no-tags -j$(nproc)

# Add KernelSU
cd ./aosp
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU/next/kernel/setup.sh" | bash -s next

#add susfs
echo "adding susfs"
cp ../../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU-Next/
cp ../../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android-6.1.patch ./
cp ../../susfs4ksu/kernel_patches/fs/susfs.c ./fs/
cp ../../susfs4ksu/kernel_patches/include/linux/susfs.h ./include/linux/
cd ./KernelSU-Next/
patch -p1 -F 3 < 10_enable_susfs_for_ksu.patch || true
cd ..
patch -p1 -F 3 < 50_add_susfs_in_gki-android-6.1.patch || true

cp ../../../kernel_patches/69_hide_stuff.patch ./
patch -p1 -F 3 < 69_hide_stuff.patch
cd ..
cp ../kernel_patches/selinux.c_fix.patch ./
patch -p1 -F 3 < selinux.c_fix.patch
cp ../kernel_patches/apk_sign.c_fix.patch ./
patch -p1 -F 3 < apk_sign.c_fix.patch
cp ../kernel_patches/Makefile_fix.patch ./
patch -p1 --fuzz=3 < ./Makefile_fix.patch

#build Kernel
sed -i "/stable_scmversion_cmd/s/-maybe-dirty/-Wild+/g" ./build/kernel/kleaf/impl/stamp.bzl
sed -i '2s/check_defconfig//' ./common/build.config.gki
echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/shusky-gki_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/shusky-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./common/arch/arm64/configs/shusky-gki_defconfig
cd ..
BUILD_AOSP_KERNEL=1 ./build_shusky.sh
