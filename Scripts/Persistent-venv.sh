#!/bin/bash
set -e

echo "=== Installing dependencies ==="
sudo apt update
sudo apt install -y python3 python3-venv python3-pip

USER_NAME="$(whoami)"
HOME_DIR="$HOME"

echo "=== Creating application directory ==="
mkdir -p "$HOME_DIR/mixbyte"
mkdir -p "$HOME_DIR/mixbyte/templates"

echo "=== Copying application files ==="
cp app.py "$HOME_DIR/mixbyte/"
cp index.html "$HOME_DIR/mixbyte/templates/"

cd "$HOME_DIR/mixbyte"

echo "=== Creating virtual environment ==="
python3 -m venv venv

echo "=== Installing Python packages ==="
source venv/bin/activate
pip install --upgrade pip
pip install flask
deactivate

echo "=== Creating systemd service ==="

sudo tee /etc/systemd/system/mixbyte.service > /dev/null <<EOF
[Unit]
Description=Mixbyte Web UI
After=network-online.target mixbyte-gadget.service
Wants=network-online.target

[Service]
User=$USER_NAME
WorkingDirectory=$HOME_DIR/mixbyte
ExecStart=$HOME_DIR/mixbyte/venv/bin/python $HOME_DIR/mixbyte/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "=== Enabling service ==="
sudo systemctl daemon-reload
sudo systemctl enable mixbyte.service
sudo systemctl restart mixbyte.service

echo
echo "=== Service Status ==="
sudo systemctl --no-pager status mixbyte.service
