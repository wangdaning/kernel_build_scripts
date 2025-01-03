#!/bin/bash

set -e

# Create the root folder with the current date and time (AM/PM)
if [ ! -d "./builds" ]; then
    echo "'builds' folder not found. Creating it..."
    mkdir -p ./builds
else
    echo "'builds' folder already exists removing it."
    rm -rf ./builds
    mkdir -p ./builds
fi

cd ./builds
ROOT_DIR="A15-SultanSU-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/android_kernel_google_zuma.git -b 15.0.0-sultan
git clone https://github.com/TheWildJames/AnyKernel3.git -b 15.0.0-sultan-zuma
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-5.15
git clone https://github.com/TheWildJames/kernel_patches.git

echo "Applying KernelSU..."
cd ./android_kernel_google_zuma
#curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/magic/kernel/setup.sh" | bash -
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU/next/kernel/setup.sh" | bash -s next

echo "Applying SUSFS patches..."
cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU-Next/
cp ../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-5.15.patch ./
cp ../susfs4ksu/kernel_patches/fs/susfs.c ./fs/
cp ../susfs4ksu/kernel_patches/include/linux/susfs.h ./include/linux/

# Apply the patches
cd ./KernelSU-Next
patch -p1 --fuzz=3 --forward < 10_enable_susfs_for_ksu.patch || true
cd ..
patch -p1 --fuzz=3 < 50_add_susfs_in_gki-android14-5.15.patch || true

cp ../kernel_patches/ksu_hooks.patch ./
patch -p1 --fuzz=3 < ./ksu_hooks.patch

cp ../kernel_patches/69_hide_stuff.patch ./
patch -p1 < 69_hide_stuff.patch

cp ../kernel_patches/apk_sign.c_fix.patch ./
patch -p1 -F 3 < apk_sign.c_fix.patch
cp ../kernel_patches/core_hook.c_fix.patch ./
patch -p1 --fuzz=3 < ./core_hook.c_fix.patch
cp ../kernel_patches/selinux.c_fix.patch ./
patch -p1 --fuzz=3 < ./selinux.c_fix.patch

cp ../kernel_patches/sys.c_fix.patch ./
patch -p1 --fuzz=3 < ./sys.c_fix.patch

cp ../kernel_patches/mount.h_fix.patch ./
patch -p1 --fuzz=3 < ./mount.h_fix.patch
cp ../kernel_patches/sched.h_fix.patch ./
patch -p1 --fuzz=3 < ./sched.h_fix.patch
cp ../kernel_patches/user.h_fix.patch ./
patch -p1 --fuzz=3 < ./user.h_fix.patch

sed -i "s/poofed_size: '%u'/poofed_size: '%llu'/g" ./fs/susfs.c
sed -i "s/length of string: %u/length of string: %lu/g" ./fs/susfs.c

# Add configuration settings for SUSFS
echo "Adding configuration settings to zuma_defconfig..."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/zuma_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/zuma_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> ./arch/arm64/configs/zuma_defconfig

# Compile the kernel
echo "Compiling the kernel..."
make zuma_defconfig -j$(nproc --all)
make -j$(nproc --all)

# Copy Image.lz4 and concatenate DTB files
echo "Copying Image.lz4 and concatenating DTB files..."
cp ./out/arch/arm64/boot/Image.lz4 ../AnyKernel3/Image.lz4
cat ./out/google-modules/soc/gs/arch/arm64/boot/dts/google/*.dtb > ../AnyKernel3/dtb

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="A15_Sultan_KernelSU_SUSFS_Zuma_$(date +'%Y_%m_%d_%H_%M_%S').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="android_kernel_google_zuma"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="Sultan With KernelSU & SUSFS for Zuma"  # Updated release name
RELEASE_NOTE="This release contains KernelSU & SUSFS v1.5.3 & Magic Mount

Module: 
https://github.com/sidex15/ksu_module_susfs

Official Manager:
https://github.com/tiann/KernelSU
Non-Official Managers:
https://github.com/rifsxd/KernelSU-Next
https://github.com/backslashxx/KernelSU
https://github.com/rsuntk/KernelSU
https://github.com/5ec1cff/KernelSU
https://github.com/silvzr/KernelSU
https://github.com/sidex15/KernelSU

Features:
[+] KernelSU
[+] SUSFS v1.5.3
[+] Maphide for LineageOS Detections
[+] Futile Maphide for jit-zygote-cache Detections
[+] Magic Mount (Must delete /data/adb/ksu/modules.img and /data/adb/modules)"

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "$RELEASE_NOTE"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
