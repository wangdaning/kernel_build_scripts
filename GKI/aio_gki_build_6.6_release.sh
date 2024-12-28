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

BUILD_CONFIGS=(
    #"android12-5.10-198-2024-01"
    #"android12-5.10-205-2024-03"
    #"android12-5.10-209-2024-05"
    #"android12-5.10-218-2024-08"
    #"android12-5.10-X-lts"

    #"android13-5.10-189-2023-11"
    #"android13-5.10-198-2024-01"
    #"android13-5.10-205-2024-03"
    #"android13-5.10-209-2024-05"
    #"android13-5.10-210-2024-06"
    #"android13-5.10-214-2024-07"
    #"android13-5.10-218-2024-08"
    #"android13-5.10-X-lts"

    #"android13-5.15-94-2023-05"
    #"android13-5.15-123-2023-11"
    #"android13-5.15-137-2024-01"
    #"android13-5.15-144-2024-03"
    #"android13-5.15-148-2024-05"
    #"android13-5.15-149-2024-07"
    #"android13-5.15-151-2024-08"
    #"android13-5.15-167-2024-11"
    #"android13-5.15-X-lts"
    
    #"android14-5.15-131-2023-11"
    #"android14-5.15-137-2024-01"
    #"android14-5.15-144-2024-03"
    #"android14-5.15-148-2024-05"
    #"android14-5.15-149-2024-06"
    #"android14-5.15-153-2024-07"
    #"android14-5.15-158-2024-08"
    #"android14-5.15-167-2024-11"
    #"android14-5.15-X-lts"

    #"android14-6.1-25-2023-10"
    #"android14-6.1-43-2023-11"
    #"android14-6.1-57-2024-01"
    #"android14-6.1-68-2024-03"
    #"android14-6.1-75-2024-05"
    #"android14-6.1-78-2024-06"
    #"android14-6.1-84-2024-07"
    #"android14-6.1-90-2024-08"
    #"android14-6.1-112-2024-11"
    #"android14-6.1-115-2024-12"
    #"android14-6.1-X-lts"
    
    #"android15-6.6-30-2024-08"
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
    IFS="-" read -r ANDROID_VERSION KERNEL_VERSION SUB_LEVEL DATE <<< "$CONFIG_DETAILS"
    
    # Formatted branch name for each build (e.g., android14-5.15-2024-01)
    FORMATTED_BRANCH="${ANDROID_VERSION}-${KERNEL_VERSION}-${DATE}"

    # Log file for this build in case of failure
    LOG_FILE="../${CONFIG}_build.log"

    echo "Starting build for $CONFIG using branch $FORMATTED_BRANCH..."
    echo "Cloning AnyKernel3 repository..."
    git clone https://github.com/TheWildJames/AnyKernel3.git -b "android14-6.1"
    echo "Cloning susfs4ksu repository..."
    git clone https://gitlab.com/simonpunk/susfs4ksu.git -b "gki-android14-6.1"
    echo "Cloning kernel_patches repository..."
    git clone https://github.com/TheWildJames/kernel_patches.git

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
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU/next/kernel/setup.sh" | bash -s next
    
    echo "Applying SUSFS patches..."
    cp ../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU-Next/
    cp ../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch ./common/
    cp ../susfs4ksu/kernel_patches/fs/susfs.c ./common/fs/
    cp ../susfs4ksu/kernel_patches/include/linux/susfs.h ./common/include/linux/

    # Apply the patches
    cd ./KernelSU-Next
    patch -p1 --forward < 10_enable_susfs_for_ksu.patch || true
    cd ../common
    patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch || true
    cp ../../kernel_patches/69_hide_stuff.patch ./
    patch -p1 -F 3 < 69_hide_stuff.patch
    sed -i '/obj-\$(CONFIG_KSU_SUSFS_SUS_SU) += sus_su.o/d' ./fs/Makefile
    cd ..
    cp ../kernel_patches/selinux.c_fix.patch ./
    patch -p1 -F 3 < selinux.c_fix.patch
    cp ../kernel_patches/apk_sign.c_fix.patch ./
    patch -p1 -F 3 < apk_sign.c_fix.patch
    cp ../kernel_patches/Makefile_fix.patch ./
    patch -p1 --fuzz=3 < ./Makefile_fix.patch

    
    # Add configuration settings for SUSFS
    echo "Adding configuration settings to gki_defconfig..."
    echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=n" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=n" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=n" >> ./common/arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=n" >> ./common/arch/arm64/configs/gki_defconfig

    # Build kernel
    echo "Building kernel for $CONFIG..."

    # Check if build.sh exists, if it does, run the default build script
    if [ -e build/build.sh ]; then
        echo "build.sh found, running default build script..."
        # Modify config files for the default build process
        sed -i '2s/check_defconfig//' ./common/build.config.gki
        sed -i "s/dirty/'Wild+'/g" ./common/scripts/setlocalversion
        LTO=thin BUILD_CONFIG=common/build.config.gki.aarch64 build/build.sh
    
        # Copying to AnyKernel3
        echo "Copying Image.lz4 to $CONFIG/AnyKernel3..."

        # Check if the boot.img file exists
        if [ "$ANDROID_VERSION" = "android12" ]; then
            mkdir bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image ./bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image.lz4 ./bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image ../
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image.lz4 ../
            gzip -n -k -f -9 ../Image >../Image.gz
            cd ./bootimgs
            
            GKI_URL=https://dl.google.com/android/gki/gki-certified-boot-android12-5.10-"${DATE}"_r1.zip
            FALLBACK_URL=https://dl.google.com/android/gki/gki-certified-boot-android12-5.10-2023-01_r1.zip
            status=$(curl -sL -w "%{http_code}" "$GKI_URL" -o /dev/null)
                
            if [ "$status" = "200" ]; then
                curl -Lo gki-kernel.zip "$GKI_URL"
            else
                echo "[+] $GKI_URL not found, using $FALLBACK_URL"
                curl -Lo gki-kernel.zip "$FALLBACK_URL"
            fi
                
                unzip gki-kernel.zip && rm gki-kernel.zip
                echo 'Unpack prebuilt boot.img'
                unpack_bootimg.py --boot_img="./boot-5.10.img"
                
                echo 'Building Image.gz'
                gzip -n -k -f -9 Image >Image.gz
                
                echo 'Building boot.img'
                mkbootimg.py --header_version 4 --kernel Image --output boot.img --ramdisk out/ramdisk --os_version 12.0.0 --os_patch_level "${DATE}"
                avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
                cp ./boot.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot.img
                
                echo 'Building boot-gz.img'
                mkbootimg.py --header_version 4 --kernel Image.gz --output boot-gz.img --ramdisk out/ramdisk --os_version 12.0.0 --os_patch_level "${DATE}"
            	avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-gz.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
                cp ./boot-gz.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-gz.img

                echo 'Building boot-lz4.img'
                mkbootimg.py --header_version 4 --kernel Image.lz4 --output boot-lz4.img --ramdisk out/ramdisk --os_version 12.0.0 --os_patch_level "${DATE}"
                avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-lz4.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
                cp ./boot-lz4.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-lz4.img
                cd ..

        elif [ "$ANDROID_VERSION" = "android13" ]; then
            mkdir bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image ./bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image.lz4 ./bootimgs
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image ../
            cp ./out/${ANDROID_VERSION}-${KERNEL_VERSION}/dist/Image.lz4 ../
            gzip -n -k -f -9 ../Image >../Image.gz
            cd ./bootimgs

            echo 'Building Image.gz'
            gzip -n -k -f -9 Image >Image.gz

            echo 'Building boot.img'
            mkbootimg.py --header_version 4 --kernel Image --output boot.img
            avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot.img
            
            echo 'Building boot-gz.img'
            mkbootimg.py --header_version 4 --kernel Image.gz --output boot-gz.img
        	avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-gz.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot-gz.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-gz.img

            echo 'Building boot-lz4.img'
            mkbootimg.py --header_version 4 --kernel Image.lz4 --output boot-lz4.img
            avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-lz4.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot-lz4.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-lz4.img
            cd ..
        fi
    else
        # Use Bazel build if build.sh exists
        echo "Running Bazel build..."
        sed -i "/stable_scmversion_cmd/s/-maybe-dirty/-Wild+/g" ./build/kernel/kleaf/impl/stamp.bzl
        sed -i '2s/check_defconfig//' ./common/build.config.gki
        rm -rf ./common/android/abi_gki_protected_exports_aarch64
        rm -rf ./common/android/abi_gki_protected_exports_x86_64
        tools/bazel build --config=fast //common:kernel_aarch64_dist
        

        # Creating Boot imgs
        echo "Creating boot.imgs..."
        if [ "$ANDROID_VERSION" = "android14" ] || [ "$ANDROID_VERSION" = "android15" ]; then
            mkdir bootimgs
            cp ./bazel-bin/common/kernel_aarch64/Image ./bootimgs
            cp ./bazel-bin/common/kernel_aarch64/Image.lz4 ./bootimgs
            cp ./bazel-bin/common/kernel_aarch64/Image ../
            cp ./bazel-bin/common/kernel_aarch64/Image.lz4 ../
            gzip -n -k -f -9 ../Image >../Image.gz
            cd ./bootimgs

            echo 'Building Image.gz'
            gzip -n -k -f -9 Image >Image.gz

            echo 'Building boot.img'
            mkbootimg.py --header_version 4 --kernel Image --output boot.img
            avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot.img
            
            echo 'Building boot-gz.img'
            mkbootimg.py --header_version 4 --kernel Image.gz --output boot-gz.img
        	avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-gz.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot-gz.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-gz.img

            echo 'Building boot-lz4.img'
            mkbootimg.py --header_version 4 --kernel Image.lz4 --output boot-lz4.img
            avbtool.py add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot-lz4.img --algorithm SHA256_RSA2048 --key /home/james/keys/testkey_rsa2048.pem
            cp ./boot-lz4.img ../../../${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}-boot-lz4.img
            cd ..
        fi
    fi

    # Create zip in the same directory
    cd ../AnyKernel3
    ZIP_NAME="AnyKernel3-${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image ./Image 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image
    ZIP_NAME="AnyKernel3-lz4-${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image.lz4 ./Image.lz4 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image.lz4
    ZIP_NAME="AnyKernel3-gz-${ANDROID_VERSION}-${KERNEL_VERSION}.${SUB_LEVEL}_${DATE}.zip"
    echo "Creating zip file: $ZIP_NAME..."
    mv ../Image.gz ./Image.gz 
    zip -r "../../$ZIP_NAME" ./*
    rm ./Image.gz
    cd ../../

    RELEASE_ZIPS["$ANDROID_VERSION-$KERNEL_VERSION.$SUB_LEVEL"]+="./$ZIP_NAME "

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

    echo "Building slowdown starts now:"
    for ((i=30; i>0; i--)); do
        echo "$i seconds remaining..."
    sleep 1
done

done

wait

echo "Build process complete."

# Collect all zip and img files
FILES=($(find ./ -type f \( -name "*.zip" -o -name "*.img" \)))

# GitHub repository details
REPO_OWNER="TheWildJames"
REPO_NAME="GKI_KernelSU_SUSFS"
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"
RELEASE_NAME="GKI Kernels With KernelSU & SUSFS v1.5.3"
RELEASE_NOTES="This release contains KernelSU and SUSFS v1.5.3

Module: https://github.com/sidex15/ksu_module_susfs

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
[+] KernelSU-Next
[+] SUSFS v1.5.3
[+] Wireguard Support
[+] Maphide LineageOS Detections
[+] Futile Maphide for jit-zygote-cache Detections
[+] Magic Mount Support
"

# Create the GitHub release
echo "Creating GitHub release: $RELEASE_NAME..."
gh release create "$TAG_NAME" "${FILES[@]}" \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "$RELEASE_NAME" \
    --notes "$RELEASE_NOTES"

echo "GitHub release created with the following files:"
printf '%s\n' "${FILES[@]}"

