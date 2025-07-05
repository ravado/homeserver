#!/bin/bash

set -e

echo "🔧 Updating package database..."
sudo apt update

# Check if gpg is installed
if ! command -v gpg &> /dev/null; then
  echo "🔑 Installing GPG..."
  sudo apt install gpg -y
else
  echo "✅ GPG is already installed."
fi

# Check if Grafana repo is already added
if ! grep -q "apt.grafana.com" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  echo "📦 Adding Grafana repository..."

  sudo mkdir -p /etc/apt/keyrings/

  # Check if grafana.gpg exists
  if [ ! -f /etc/apt/keyrings/grafana.gpg ]; then
    echo "🔑 Adding Grafana GPG key..."
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
  else
    echo "✅ Grafana GPG key already exists."
  fi

  echo "📂 Adding Grafana source list..."
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

  echo "🔄 Updating package database after adding Grafana repo..."
  sudo apt update
else
  echo "✅ Grafana repository is already added."
fi

# Check if alloy is already installed
if ! command -v alloy &> /dev/null; then
  echo "📥 Installing Alloy..."
  sudo apt install alloy -y
else
  echo "✅ Alloy is already installed."
fi

# Prompt for Loki URL with validation
while true; do
  echo "🌐 Please enter your Loki URL (e.g. http://192.168.91.107:3100/loki/api/v1/push):"
  read loki_url

  # Basic validation for non-empty and starts with http
  if [[ -z "$loki_url" ]]; then
    echo "❌ URL cannot be empty. Please try again."
  elif [[ ! "$loki_url" =~ ^http ]]; then
    echo "❌ URL must start with http or https. Please try again."
  else
    echo "✅ Loki URL set to: $loki_url"
    break
  fi
done

echo "⬇️ Downloading Alloy config template..."
sudo curl -fsSL https://raw.githubusercontent.com/ravado/homeserver/refs/heads/main/logs-and-monitoring/default_config_alloy.sh -o /etc/alloy/config.alloy

echo "✏️ Replacing Loki URL placeholder with provided value..."
sudo sed -i "s|\${LOKI_URL}|${loki_url}|g" /etc/alloy/config.alloy

echo "🧪 Validating configuration..."
sudo alloy validate /etc/alloy/config.alloy

echo "🔄 Restarting and enabling Alloy service..."
sudo systemctl restart alloy
sudo systemctl enable --now alloy

echo "✅ Alloy installation and configuration completed successfully!"
