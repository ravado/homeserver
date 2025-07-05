#!/bin/bash

set -e

echo "🔧 Updating packages..."
sudo apt update

echo "🔧 Installing GPG..."
sudo apt install -y gpg

echo "🔧 Adding Grafana repository..."
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

echo "🔧 Updating package list again..."
sudo apt update

echo "🔧 Installing Alloy..."
sudo apt install -y alloy

# echo "🔧 Configuring Alloy UI access..."
# echo 'CUSTOM_ARGS="--server.http.listen-addr=0.0.0.0:12345"' | sudo tee /etc/default/alloy

echo "🔧 Enabling and starting Alloy service..."
sudo systemctl enable --now alloy

echo "✅ Alloy installation complete. Now you can access the Alloy UI at http://<your-server-ip>:12345"
echo "⚙️ Configuration file is located at /etc/alloy/config.alloy"
sudo systemctl status alloy
