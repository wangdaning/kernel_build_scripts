#!/bin/bash

# Function to ask a yes/no question with a default answer of 'yes'
ask_question() {
    local question="$1"
    while true; do
        read -p "$question (Y/n): " choice
        case "$choice" in
            "" | [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# Flags to track user choices
build_pixel8=false
build_pixel7=false

# Ask if the user wants to build Pixel 8
if ask_question "Do you want to build Pixel 8 (./A15_zuma_build_kernel_susfs_release.sh)?"; then
    build_pixel8=true
fi

# Ask if the user wants to build Pixel 7
if ask_question "Do you want to build Pixel 7 (./A15_gs201_build_kernel_susfs_release.sh)?"; then
    build_pixel7=true
fi

# Execute based on user choices
if [ "$build_pixel8" = true ]; then
    echo "Building Pixel 8 (./A15_zuma_build_kernel_susfs_release.sh)..."
    chmod +x ./A15_zuma_build_kernel_susfs_release.sh  # Make it executable if it's a script
    ./A15_zuma_build_kernel_susfs_release.sh
else
    echo "Skipping build of Pixel 8."
fi

if [ "$build_pixel7" = true ]; then
    echo "Building Pixel 7 (./A15_gs201_build_kernel_susfs_release.sh)..."
    chmod +x ./A15_gs201_build_kernel_susfs_release.sh  # Make it executable if it's a script
    ./A15_gs201_build_kernel_susfs_release.sh
else
    echo "Skipping build of Pixel 7."
fi
