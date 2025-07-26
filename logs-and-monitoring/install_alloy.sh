#!/bin/bash

set -e

echo "🔧 Updating package database..."
sudo apt update

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "📥 Installing curl..."
  sudo apt install curl -y
else
  echo "✅ curl is already installed."
fi

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

# Prompt for Loki host
while true; do
  echo "🌐 Please enter your Loki IP or domain (e.g. 192.168.91.10):"
  read loki_host

  if [[ -z "$loki_host" ]]; then
    echo "❌ Loki host cannot be empty. Please try again."
  else
    break
  fi
done

# Prompt for Prometheus host
while true; do
  echo "🌐 Please enter your Prometheus IP or domain (e.g. 192.168.91.10):"
  read prometheus_host

  if [[ -z "$prometheus_host" ]]; then
    echo "❌ Prometheus host cannot be empty. Please try again."
  else
    break
  fi
done

# Use fixed API paths
loki_url="http://${loki_host}:3100/loki/api/v1/push"
prometheus_url="http://${prometheus_host}:9090/api/v1/write"

echo "✅ Loki URL set to: $loki_url"
echo "✅ Prometheus URL set to: $prometheus_url"

echo "⬇️ Downloading Alloy config template..."
sudo curl -fsSL https://raw.githubusercontent.com/ravado/homeserver/refs/heads/main/logs-and-monitoring/default_config.alloy -o /etc/alloy/config.alloy

echo "✏️ Replacing placeholders in config..."
sudo sed -i "s|\${LOKI_URL}|${loki_url}|g" /etc/alloy/config.alloy
sudo sed -i "s|\${PROMETHEUS_URL}|${prometheus_host}|g" /etc/alloy/config.alloy

echo "🧪 Validating configuration..."
sudo alloy validate /etc/alloy/config.alloy

echo "🔄 Restarting and enabling Alloy service..."
sudo systemctl enable --now alloy

echo "✅ Alloy installation and configuration completed successfully!"
