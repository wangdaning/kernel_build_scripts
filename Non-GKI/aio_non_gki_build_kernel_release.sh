#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

#DO NOT GO OVER 4
MAX_CONCURRENT_BUILDS=1

# Check if 'builds' folder exists, create it if not
if [ ! -d "./builds" ]; then
    echo "'builds' folder not found. Creating it..."
    mkdir -p ./builds
else
    echo "'builds' folder already exists removing it."
    rm -rf ./builds
    mkdir -p ./builds
fi

cd ./builds
ROOT_DIR="GKI-AIO-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder: $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Array with configurations (e.g., android-version-kernel-version-date)
BUILD_CONFIGS=(
    #"android-4.9"
    "android-4.14-stable"
    #android-4.19-stable"
    #"android11-5.4"
    #"android12-5.4"
)

# Arrays to store generated zip files, grouped by androidversion-kernelversion
declare -A RELEASE_ZIPS=()

# Iterate over configurations
build_config() {
    CONFIG=$1
    CONFIG_DETAILS=${CONFIG}

    # Create a directory named after the current configuration
    echo "Creating folder for configuration: $CONFIG..."
    mkdir -p "$CONFIG"
    cd "$CONFIG"
    
    # Split the config details into individual components
    IFS="-" read -r ANDROID_VERSION KERNEL_VERSION STABLE <<< "$CONFIG_DETAILS"
    
    # Formatted branch name for each build (e.g., android14-5.15-2024-01)
    if [ "${STABLE:-}" = "stable" ]; then
        FORMATTED_BRANCH="${ANDROID_VERSION}-${KERNEL_VERSION}-${STABLE}"
    else
        FORMATTED_BRANCH="${ANDROID_VERSION}-${KERNEL_VERSION}"
    fi


    # Log file for this build in case of failure
    LOG_FILE="../${CONFIG}_build.log"

    echo "Starting build for $CONFIG using branch $FORMATTED_BRANCH..."
    # Check if AnyKernel3 repo exists, remove it if it does
    if [ -d "./AnyKernel3" ]; then
        echo "Removing existing AnyKernel3 directory..."
        rm -rf ./AnyKernel3
    fi
    echo "Cloning AnyKernel3 repository..."
    git clone https://github.com/TheWildJames/AnyKernel3.git -b "${ANDROID_VERSION}-${KERNEL_VERSION}"

    # Check if susfs4ksu repo exists, remove it if it does
    if [ -d "./susfs4ksu" ]; then
        echo "Removing existing susfs4ksu directory..."
        rm -rf ./susfs4ksu
    fi
    echo "Cloning susfs4ksu repository..."
    git clone https://gitlab.com/simonpunk/susfs4ksu.git -b "kernel-${KERNEL_VERSION}"

    # Setup directory for each build
    SOURCE_DIR="/home/james/android_kernels/$CONFIG"

    # Check if the source directory exists and is a directory
    if [ -d "$SOURCE_DIR" ]; then
        # Copy the directory to the current working directory
        echo "Copying $SOURCE_DIR to ./"
        cp -r "$SOURCE_DIR" ./
        echo "Successfully copied $SOURCE_DIR to ./"
    else
        mkdir -p "$CONFIG"
    fi
    
    cd "$CONFIG"

    # Initialize and sync kernel source with updated repo commands
    echo "Initializing and syncing kernel source..."
    repo init --depth=1 --u https://android.googlesource.com/kernel/manifest -b common-${FORMATTED_BRANCH}
    REMOTE_BRANCH=$(git ls-remote https://android.googlesource.com/kernel/common ${FORMATTED_BRANCH})
    DEFAULT_MANIFEST_PATH=.repo/manifests/default.xml
    
    # Check if the branch is deprecated and adjust the manifest
    if grep -q deprecated <<< $REMOTE_BRANCH; then
        echo "Found deprecated branch: $FORMATTED_BRANCH"
        sed -i "s/\"${FORMATTED_BRANCH}\"/\"deprecated\/${FORMATTED_BRANCH}\"/g" $DEFAULT_MANIFEST_PATH
    fi

    # Verify repo version and sync
    repo --version
    repo --trace sync -c -j$(nproc --all) --no-tags --fail-fast

    # Apply KernelSU and SUSFS patches
    echo "Adding KernelSU..."
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5

    echo "Applying SUSFS patches..."
    cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU/
    cp ../susfs4ksu/kernel_patches/50_add_susfs_in_kernel-${KERNEL_VERSION}.patch ./common/
    cp ../susfs4ksu/kernel_patches/fs/susfs.c ./common/fs/
    cp ../susfs4ksu/kernel_patches/include/linux/susfs.h ./common/include/linux/
    cp ../susfs4ksu/kernel_patches/fs/sus_su.c ./common/fs/
    cp ../susfs4ksu/kernel_patches/include/linux/sus_su.h ./common/include/linux/

    # Apply the patches
    cd ./KernelSU
    patch -p1 -f -F 3 < 10_enable_susfs_for_ksu.patch || true
    cd ../common
    patch -p1 -f -F 3 < 50_add_susfs_in_kernel-${KERNEL_VERSION}.patch || true
    cd ..

    # Add configuration settings for SUSFS
    echo "Adding configuration settings to defconfig..."
    echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./common/arch/arm64/configs/defconfig
    echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./common/arch/arm64/configs/defconfig

    # Build kernel
    echo "Building kernel for $CONFIG..."
    #sed -i '2s/check_defconfig//' ./common/build.config.aarch64
    #sed -i "s/dirty/'Wild+'/g" ./common/scripts/setlocalversion
    cd ./common
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig -j$(nproc)
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- -j$(nproc)
    #LTO=thin BUILD_CONFIG=common/build.config.aarch64 build/build.sh
    
    # Copying to AnyKernel3
    echo "Copying Image.lz4 to $CONFIG/AnyKernel3..."
    cp ./out/${FORMATTED_BRANCH}/dist/Image ../
    gzip -n -k -f -9 ../Image >../Image.gz
    gzip -n -k -f -9 ../Image >../Image.lz4

    # Create zip in the same directory
    cd ../AnyKernel3
    ZIP_NAME="AnyKernel3-${FORMATTED_BRANCH}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image ./Image 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image
    ZIP_NAME="AnyKernel3-lz4-${FORMATTED_BRANCH}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image.lz4 ./Image.lz4 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image.lz4
    ZIP_NAME="AnyKernel3-gz-${FORMATTED_BRANCH}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image.gz ./Image.gz 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image.gz
    cd ../../

    RELEASE_ZIPS["$FORMATTED_BRANCH"]+="./$ZIP_NAME "

    # Delete the $CONFIG folder after building
    echo "Deleting $CONFIG folder..."
    rm -rf "$CONFIG"
}

# Concurrent build management
for CONFIG in "${BUILD_CONFIGS[@]}"; do
    # Start the build process in the background
    build_config "$CONFIG" &

    # Limit concurrent jobs to $MAX_CONCURRENT_BUILDS
    while (( $(jobs -r | wc -l) >= MAX_CONCURRENT_BUILDS )); do
        sleep 1  # Check every second for free slots
    done
done

wait

echo "Build process complete."

# Collect all zip and img files
FILES=($(find ./ -type f \( -name "*.zip" -o -name "*.img" \)))

# GitHub repository details
REPO_OWNER="TheWildJames"
REPO_NAME="Non_GKI_KernelSU_SUSFS"
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"
RELEASE_NAME="Non-GKI Kernels With KernelSU & SUSFS v1.5.2"
RELEASE_NOTES="This release contains KernelSU and SUSFS v1.5.2"

# Create the GitHub release
echo "Creating GitHub release: $RELEASE_NAME..."
gh release create "$TAG_NAME" "${FILES[@]}" \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "$RELEASE_NAME" \
    --notes "$RELEASE_NOTES"

echo "GitHub release created with the following files:"
printf '%s\n' "${FILES[@]}"

