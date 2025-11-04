#!/usr/bin/env bash
set -e

echo "🔍 Detecting connected USB drives..."
echo

# Detect removable USB drives
mapfile -t usbs < <(lsblk -dno NAME,TRAN,SIZE,MODEL | grep usb | awk '{print $1}')
if [ ${#usbs[@]} -eq 0 ]; then
    echo "❌ No USB drives detected. Plug one in and try again."
    exit 1
fi

# Auto-select if only one USB found
if [ ${#usbs[@]} -eq 1 ]; then
    devname="${usbs[0]}"
    echo "🧠 Automatically selected USB: /dev/$devname"
else
    echo "💽 Available USB drives:"
    lsblk -dno NAME,TRAN,SIZE,MODEL | grep usb | nl
    echo
    read -p "Enter the USB device number to use: " usbnum
    devname="${usbs[$((usbnum-1))]}"
fi

dev="/dev/$devname"

# Sanity check
if [ ! -b "$dev" ]; then
    echo "❌ Device $dev not found."
    exit 1
fi

# List ISO files
isos=(*.iso)
if [ ${#isos[@]} -eq 0 ]; then
    echo "❌ No .iso files found in this directory."
    exit 1
fi

echo
echo "📂 Available ISO files:"
for i in "${!isos[@]}"; do
    printf "  [%d] %s\n" $((i+1)) "${isos[$i]}"
done
echo
read -p "Select ISO number to burn: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#isos[@]} )); then
    echo "❌ Invalid selection."
    exit 1
fi

iso="${isos[$((choice-1))]}"
echo
echo "➡️  Selected: $iso"
echo "⚠️  This will ERASE all data on $dev!"

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
sync

echo
echo "🔍 Verifying written data..."
if sudo cmp -n "$(stat -c%s "$iso")" "$iso" "$dev"; then
    echo "✅ Verification successful — data matches the ISO!"
else
    echo "⚠️ Verification failed — data differs!"
fi

echo
echo "🔌 Ejecting USB drive..."
if command -v eject >/dev/null 2>&1; then
    sudo eject "$dev" || echo "⚠️ Could not eject $dev (may not support it)"
else
    echo "⚠️ 'eject' command not installed — skipping eject step."
fi

echo
echo "🎉 All done! $iso successfully written to $devname."
