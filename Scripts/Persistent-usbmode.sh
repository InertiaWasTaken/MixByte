#!/bin/bash
set -e

echo "=== Configuring USB Gadget Support ==="

CMDLINE="/boot/firmware/cmdline.txt"

if ! grep -q "modules-load=dwc2,libcomposite" "$CMDLINE"; then
echo "Adding USB gadget modules to cmdline.txt"

```
sudo sed -i \
    's@$@ modules-load=dwc2,libcomposite@' \
    "$CMDLINE"
```

else
echo "USB gadget modules already configured"
fi

echo "=== Loading libcomposite ==="
sudo modprobe libcomposite

echo "=== Installing gadget script ==="

sudo tee /usr/local/bin/mixbyte-gadget.sh > /dev/null <<'EOF'
#!/bin/bash
set -e

G=/sys/kernel/config/usb_gadget/mixbyte

# Cleanup previous instance

if [ -d "$G" ]; then
echo "" > "$G/UDC" 2>/dev/null || true
rm -f "$G"/configs/c.1/* 2>/dev/null || true
rm -rf "$G"/functions/* 2>/dev/null || true
rm -rf "$G" 2>/dev/null || true
fi

mkdir -p "$G"
cd "$G"

# Identity

echo 0x1d6b > idVendor
echo 0x0104 > idProduct

mkdir -p strings/0x409

echo "MixByte" > strings/0x409/manufacturer
echo "MixByte Composite Device" > strings/0x409/product
echo "0001" > strings/0x409/serialnumber

# Configuration

mkdir -p configs/c.1/strings/0x409
echo "Ethernet + Audio" > configs/c.1/strings/0x409/configuration

# Windows Ethernet

mkdir -p functions/rndis.usb0
ln -s functions/rndis.usb0 configs/c.1/

# USB Audio Class 2

mkdir -p functions/uac2.usb0

echo 48000 > functions/uac2.usb0/c_srate
echo 2 > functions/uac2.usb0/c_chmask

echo 48000 > functions/uac2.usb0/p_srate
echo 2 > functions/uac2.usb0/p_chmask

ln -s functions/uac2.usb0 configs/c.1/

# Bind gadget

UDC=$(ls /sys/class/udc | head -n1)
echo "$UDC" > UDC

echo "MixByte gadget started"
EOF

sudo chmod +x /usr/local/bin/mixbyte-gadget.sh

echo "=== Creating systemd service ==="

sudo tee /etc/systemd/system/mixbyte-gadget.service > /dev/null <<'EOF'
[Unit]
Description=MixByte USB Gadget
After=local-fs.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mixbyte-gadget.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling gadget service ==="

sudo systemctl daemon-reload
sudo systemctl enable mixbyte-gadget.service
sudo systemctl restart mixbyte-gadget.service

echo
echo "=== Gadget Status ==="
sudo systemctl --no-pager status mixbyte-gadget.service
