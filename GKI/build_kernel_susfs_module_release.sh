#!/bin/bash

# Create the root folder with the current date and time (AM/PM)
cd ./builds
ROOT_DIR="Module-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/susfs4ksu.git -b gki-android14-5.15-1.5.2
git clone https://github.com/sidex15/ksu_module_susfs.git

# Building tools
echo "Building tools..."
cd ./susfs4ksu
chmod +x ./build_ksu_susfs_tool.sh
./build_ksu_susfs_tool.sh
chmod +x ./build_sus_su_tool.sh
./build_sus_su_tool.sh

cd ..
#./build_ksu_module.sh

exit


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
RELEASE_NAME="GKI With KernelSU With susfs for Zuma"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release for Zuma"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
