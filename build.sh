#!/bin/bash

set -e

echo "================================================"
echo " N100 DSI Black Screen Fix - Kernel Build"
echo "================================================"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./build.sh)"
    exit 1
fi

KERNEL_VERSION=$(uname -r)
SOURCE_DIR=/usr/src/linux-source-7.0.0
TARBALL=/usr/src/linux-source-7.0.0.tar.bz2

echo "Kernel version: $KERNEL_VERSION"
echo ""

# Install dependencies
echo "Installing dependencies..."
apt-get install -y linux-source build-essential libncurses-dev \
    bison flex libssl-dev libelf-dev libdw-dev

# Extract source if needed
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Extracting kernel source..."
    tar xf "$TARBALL" -C /usr/src/
fi

# Apply patches
echo "Applying patches..."
cd "$SOURCE_DIR"

for patch in intel_ddi intel_modeset_setup intel_dsi; do
    PATCH_FILE="$(dirname "$0")/kernel-patches/${patch}.patch"
    if patch --dry-run -p1 < "$PATCH_FILE" > /dev/null 2>&1; then
        echo "Applying ${patch}.patch..."
        patch -p1 < "$PATCH_FILE"
    else
        echo "${patch}.patch already applied or not needed, skipping."
    fi
done

# Setup build environment
echo "Setting up build environment..."
cp /boot/config-$KERNEL_VERSION .config
make olddefconfig
make prepare scripts

# Copy required headers
echo "Copying headers..."
find /usr/src/linux-source-7.0.0/drivers/gpu/drm/i915 -name "*.h" | while read f; do
    dest="/usr/src/linux-headers-${KERNEL_VERSION%-generic}*-generic/${f#/usr/src/linux-source-7.0.0/}"
    mkdir -p "$(dirname $dest)"
    cp "$f" "$dest" 2>/dev/null || true
done

# Fix trace headers
HEADERS_DIR=$(ls -d /usr/src/linux-headers-${KERNEL_VERSION%-generic}*-generic 2>/dev/null | head -1)
cp drivers/gpu/drm/i915/intel_uncore_trace.h "$HEADERS_DIR/drivers/gpu/drm/i915/"
cp drivers/gpu/drm/i915/display/intel_display_trace.h "$HEADERS_DIR/drivers/gpu/drm/i915/display/"

# Compile module
echo "Compiling i915 module..."
make -j$(nproc) \
    -C /usr/lib/modules/$KERNEL_VERSION/build \
    M=$(pwd)/drivers/gpu/drm/i915 \
    EXTRA_CFLAGS="-I$(pwd)/drivers/gpu/drm/i915" \
    modules

# Install module
echo "Installing module..."
cp drivers/gpu/drm/i915/i915.ko \
    /lib/modules/$KERNEL_VERSION/kernel/drivers/gpu/drm/i915/i915.ko
depmod -a
update-initramfs -u

echo ""
echo "================================================"
echo " Kernel module built and installed successfully!"
echo " Please reboot your system."
echo "================================================"
