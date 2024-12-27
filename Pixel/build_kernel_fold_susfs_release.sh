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
ROOT_DIR="Fold-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/AnyKernel3.git -b android14-5.15
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-5.15
git clone https://github.com/TheWildJames/lineage_kernel_patches.git

# Get the kernel
echo "Get the kernel..."
mkdir ./fold
cd ./fold
repo init -u https://android.googlesource.com/kernel/manifest  --depth=1 -b android-gs-felix-5.10-android15-qpr1
repo sync --current-branch --no-tags -j$(nproc)

# Add KernelSU
cd ./aosp
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -

#add susfs
echo "adding susfs"
cp ../../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU/
cp ../../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-5.15.patch ./
cp ../../susfs4ksu/kernel_patches/fs/susfs.c ./fs/
cp ../../susfs4ksu/kernel_patches/include/linux/susfs.h ./include/linux/
cp ../../susfs4ksu/kernel_patches/fs/sus_su.c ./fs/
cp ../../susfs4ksu/kernel_patches/include/linux/sus_su.h ./include/linux/
cd ./KernelSU/
patch -p1 -F 3 -f < 10_enable_susfs_for_ksu.patch
cd ..
patch -p1 -F 3 -f < 50_add_susfs_in_gki-android14-5.15.patch

#adding lineage patch
#cd ../../
#cp ../lineage_kernel_patches/69_hide_lineage.patch ./android14-5.15
#cd ./fold
#patch -p1 < 69_hide_lineage.patch

#build Kernel
sed -i "/stable_scmversion_cmd/s/-maybe-dirty/-Wild-Exclusive+/g" ../build/kernel/kleaf/impl/stamp.bzl
#sed -i '2s/check_defconfig//' ./build.config.gki
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/gki_defconfig
cd ..
./build_felix.sh


exit

# Copy Image.lz4
echo "Copying Image.lz4"
cp ./bazel-bin/common/kernel_aarch64/Image.lz4 ../AnyKernel3/Image.lz4

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="GKI-android14-5.15-KernelSU-SUSFS-$(date +'%Y-%m-%d-%H-%M-%S').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="android14-5.15"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="GKI-android14-5.15 With KernelSU & SUSFS"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
