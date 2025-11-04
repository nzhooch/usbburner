#!/usr/bin/env bash
set -e

echo "🔍 Detecting USB drives..."
echo

# List removable drives
lsblk -dno NAME,TRAN,SIZE,MODEL | grep usb || {
    echo "❌ No USB drives detected. Plug one in and try again."
    exit 1
}

echo
read -p "Enter the USB device name (e.g., sdb): /dev/" devname
dev="/dev/$devname"

# Sanity check
if [ ! -b "$dev" ]; then
    echo "❌ Device $dev not found."
    exit 1
fi

# Ask for ISO file in current directory
echo
echo "📂 ISO files in current directory:"
ls *.iso 2>/dev/null || { echo "No .iso files found!"; exit 1; }

echo
read -p "Enter ISO filename: " iso

if [ ! -f "$iso" ]; then
    echo "❌ File $iso not found."
    exit 1
fi

echo
echo "⚠️ WARNING: This will ERASE all data on $dev!"
read -p "Type 'YES' to continue: " confirm
if [ "$confirm" != "YES" ]; then
    echo "Cancelled."
    exit 0
fi

echo
echo "Unmounting any partitions on $dev..."
sudo umount ${dev}?* 2>/dev/null || true

echo
echo "💿 Writing $iso to $dev..."
sudo dd if="$iso" of="$dev" bs=4M status=progress conv=fsync

echo
sync
echo "✅ Done! $iso written to $dev successfully."
