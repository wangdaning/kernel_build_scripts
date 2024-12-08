#!/bin/bash

# Exit immediately if a command exits with a non-zero status
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
ROOT_DIR="android-4.14-SUSFS-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/android_kernel_samsung_exynos9820.git
git clone https://github.com/TheWildJames/AnyKernel3.git -b android12-5.10
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b kernel-4.14

# Get the kernel
echo "Get the kernel..."
cd ./android_kernel_samsung_exynos9820
rm -rf ./KernelSU

# Add KernelSU
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5

#add susfs
echo "adding susfs"
cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU/
cp ../susfs4ksu/kernel_patches/50_add_susfs_in_kernel-4.14.patch ./
cp ../susfs4ksu/kernel_patches/fs/* ./fs/
cp ../susfs4ksu/kernel_patches/include/linux/* ./include/linux/
cd ./KernelSU
patch -p1 -F 3 < 10_enable_susfs_for_ksu.patch
cd ..
patch -p1 -F 3 < 50_add_susfs_in_kernel-4.14.patch

#add KSU Config
echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond0lte_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond0lteks_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond1lte_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond1lteks_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond2lte_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyond2lteks_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyondx_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_beyondxks_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_d1_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_d1_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_d1xks_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_d2s_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_d2s_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_d2x_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_d2x_defconfig

echo "Adding CONFIG_KSU.."
echo "CONFIG_KSU=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./arch/arm64/configs/extreme_d2xks_defconfig
#build Kernel
echo "Building Kernel.."
./build.sh -m d1

exit

# Copy Image.lz4
echo "Copying Image.lz4"
cp ./out/android12-5.10/dist/Image.lz4 ../AnyKernel3/Image.lz4

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="GKI-android12-5.10-KernelSU-SUSFS-$(date +'%Y-%m-%d-%H-%M-%S').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="android12-5.10"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="GKI android12-5.10 With KernelSU & SUSFS"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
