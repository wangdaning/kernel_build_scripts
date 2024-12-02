#!/bin/bash

# Create the root folder with the current date and time (AM/PM)
ROOT_DIR="A14-SultanSU-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone --recursive https://github.com/TheWildJames/android_kernel_google_zuma.git -b 14.0.0-sultan
git clone https://github.com/TheWildJames/AnyKernel3.git -b 14.0.0-sultan

# Compile the kernel
echo "Compiling the kernel..."
cd ./android_kernel_google_zuma
make zuma_defconfig
make -j$(nproc)

# Copy Image.lz4 and concatenate DTB files
echo "Copying Image.lz4 and concatenating DTB files..."
cp ./out/arch/arm64/boot/Image.lz4 ../AnyKernel3/Image.lz4
cat ./out/google-modules/soc/gs/arch/arm64/boot/dts/google/*.dtb > ../AnyKernel3/dtb

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="A14_Sultan_KernelSU_Zuma_$(date +'%Y_%m_%d').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="android_kernel_google_zuma"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="Sultan With KernelSU for Zuma"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release for Zuma"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
