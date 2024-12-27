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
ROOT_DIR="Redbull-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.19
git clone https://github.com/TheWildJames/kernel_patches.git

# Get the kernel
echo "Get the kernel..."
mkdir redbull
cd ./redbull
repo init -u https://android.googlesource.com/kernel/manifest  --depth=1 -b android-msm-redbull-4.19-android14-qpr3
repo sync --current-branch --no-tags -j$(nproc)

# Add KernelSU
cd ./private/msm-google
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU/next/kernel/setup.sh" | bash -s susfs-4.19

#add susfs
echo "adding susfs"
#cp ../../../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU-Next/
cp ../../../susfs4ksu/kernel_patches/50_add_susfs_in_kernel-4.19.patch ./
cp ../../../susfs4ksu/kernel_patches/fs/susfs.c ./fs/
cp ../../../susfs4ksu/kernel_patches/include/linux/susfs.h ./include/linux/
#cd ./KernelSU-Next/
#patch -p1 -F 3 < 10_enable_susfs_for_ksu.patch
#cd ..
patch -p1 -F 3 < 50_add_susfs_in_kernel-4.19.patch

echo "adding hooks patch"
cp ../../../kernel_patches/ksu_hooks_4.14.patch ./
patch -p1 -F 3 < ksu_hooks_4.14.patch
cp ../../../kernel_patches/69_hide_stuff.patch ./
patch -p1 -F 3 < 69_hide_stuff.patch

#echo "adding kernel_comapt.c fix"
#cp ../../../kernel_patches/kernel_compat.c_fix.patch ./
#patch -p1 --fuzz=3 < ./kernel_compat.c_fix.patch

#build Kernel
sed -i '2s/check_defconfig//' ./build.config.gki
sed -i "s/dirty/'Wild+'/g" ./scripts/setlocalversion
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/redbull-gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> ./arch/arm64/configs/redbull-gki_defconfig
cd ../../
BUILD_AOSP_KERNEL=1 ./build_redbull-gki.sh

# Copy Image.lz4
echo "Copying Image.lz4"
cp ./out/android-msm-pixel-4.19/dist/boot.img ./
cp ./out/android-msm-pixel-4.19/dist/dtbo_barbet.img ./
cp ./out/android-msm-pixel-4.19/dist/dtbo_redfin.img ./
cp ./out/android-msm-pixel-4.19/dist/dtbo_bramble.img ./
cp ./out/android-msm-pixel-4.19/dist/vendor_boot.img ./

FILES=($(find ./ -maxdepth 1 -type f -name "*.img"))

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="Pixel_KernelSU_SUSFS"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="Redbull With KernelSU & SUSFS"  # Updated release name
RELEASE_NOTES="This release contains KernelSU and SUSFS v1.5.3

Module: 
https://github.com/sidex15/ksu_module_susfs

Managers: 
https://github.com/rifsxd/KernelSU-Next
https://github.com/tiann/KernelSU

Features:
[+] KernelSU-Next
[+] SUSFS v1.5.3
[+] Maphide LineageOS Detections
[+] Futile Maphide for jit-zygote-cache Detections
[+] Magic Mount (Must delete /data/adb/ksu/modules.img and /data/adb/modules) 
"

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "${FILES[@]}" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "$RELEASE_NOTES"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
