#!/bin/bash
set -e

G=/sys/kernel/config/usb_gadget/mixbyte

echo "[MixByte] starting gadget..."

# Wait for configfs to be writable
if [ ! -w /sys/kernel/config/usb_gadget ]; then
    echo "[MixByte] configfs not ready"
    exit 1
fi

# -------------------------
# SAFE UNBIND (DO NOT DELETE GADGET TREE)
# -------------------------
if [ -d "$G" ]; then
    echo "" > $G/UDC 2>/dev/null || true
    sleep 0.2

    # clear old config links safely
    rm -f configs/c.1/*.usb0 2>/dev/null || true
fi

# -------------------------
# CREATE GADGET
# -------------------------
mkdir -p $G
cd $G

# -------------------------
# USB IDENTITY
# -------------------------
echo 0x1d6b > idVendor
echo 0x0104 > idProduct

mkdir -p strings/0x409
echo "MixByte" > strings/0x409/manufacturer
echo "MixByte Composite Device" > strings/0x409/product
echo "0001" > strings/0x409/serialnumber

# -------------------------
# CONFIG
# -------------------------
mkdir -p configs/c.1/strings/0x409
echo "MixByte Config" > configs/c.1/strings/0x409/configuration

# -------------------------
# USB ETHERNET (RNDIS)
# -------------------------
mkdir -p functions/rndis.usb0

if [ ! -L configs/c.1/rndis.usb0 ]; then
    ln -s functions/rndis.usb0 configs/c.1/
fi

# -------------------------
# USB AUDIO (UAC2)
# -------------------------
mkdir -p functions/uac2.usb0

# mic (capture)
echo 48000 > functions/uac2.usb0/c_srate
echo 2 > functions/uac2.usb0/c_chmask

# speaker (playback)
echo 48000 > functions/uac2.usb0/p_srate
echo 2 > functions/uac2.usb0/p_chmask

if [ ! -L configs/c.1/uac2.usb0 ]; then
    ln -s functions/uac2.usb0 configs/c.1/
fi

# -------------------------
# WAIT FOR UDC
# -------------------------
UDC=""
for i in {1..50}; do
    UDC=$(ls /sys/class/udc 2>/dev/null | head -n 1)
    [ -n "$UDC" ] && break
    sleep 0.1
done

if [ -z "$UDC" ]; then
    echo "[MixByte] ERROR: no UDC found"
    exit 1
fi

sleep 1

echo "$UDC" > UDC

echo "[MixByte] gadget active on $UDC"

