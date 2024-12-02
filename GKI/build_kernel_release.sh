#!/bin/bash

# Create the root folder with the current date and time (AM/PM)
cd ./builds
ROOT_DIR="GKI-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/android14-5.15.git
git clone https://github.com/TheWildJames/AnyKernel3.git -b common-android14-5.15

# Get the kernel
echo "Get the kernel..."
cd ./common-android14-5.15
repo init -u https://android.googlesource.com/kernel/manifest
mv manifest_12637676.xml .repo/manifests
repo init -m manifest_12637676.xml
repo sync
rm -rf ./common/android/abi_gki_protected_exports_aarch64
rm -rf ./common/android/abi_gki_protected_exports_x86_64

# Add KernelSU
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -

#build Kernel
tools/bazel build --config=fast //common:kernel_aarch64_dist


exit


# Copy Image.lz4
echo "Copying Image.lz4"
cp ./bazel-bin/common/kernel_aarch64/Image.lz4 ../AnyKernel3/Image.lz4

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="GKI_KernelSU_Zuma_$(date +'%Y_%m_%d_%H_%M_%S').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="common-android14-5.15"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="GKI With KernelSU for Zuma"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release for Zuma"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
