#!/bin/bash

set -e

echo "=== Installing ttyd ==="

wget -O /tmp/ttyd.aarch64 
https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.aarch64

chmod +x /tmp/ttyd.aarch64

sudo mv /tmp/ttyd.aarch64 /usr/local/bin/ttyd

echo
echo "=== ttyd Version ==="
ttyd --version

echo
echo "=== Creating systemd service ==="

sudo tee /etc/systemd/system/mixbyte-terminal.service > /dev/null <<'EOF'
[Unit]
Description=Mixbyte Terminal
After=network.target

[Service]
ExecStart=/usr/local/bin/ttyd -W -p 7681 /bin/bash
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo
echo "=== Enabling service ==="

sudo systemctl daemon-reload
sudo systemctl enable mixbyte-terminal.service
sudo systemctl restart mixbyte-terminal.service

echo
echo "=== Service Status ==="

sudo systemctl --no-pager status mixbyte-terminal.service

echo
echo "Done."
echo "Open: http://<pi-ip>:7681"
