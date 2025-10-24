#!/usr/bin/env bash
set -euo pipefail

echo "🌐 === Встановлення та підключення Tailscale ==="

# --- 🧠 Hostname input ---
CURRENT_HOST=$(hostname)
read -rp "📛 Введи hostname для цього пристрою [$CURRENT_HOST]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$CURRENT_HOST}

# --- 🔐 SSH toggle ---
read -rp "🔑 Дозволити SSH через Tailscale? (yes/NO): " enable_ssh
enable_ssh=${enable_ssh,,}
SSH_FLAG=""
if [[ "$enable_ssh" == "yes" ]]; then
    SSH_FLAG="--ssh"
fi

echo "=============================================="
echo "🧾 Налаштування:"
echo "   Hostname: $HOSTNAME"
echo "   SSH через Tailscale: ${enable_ssh:-no}"
echo "=============================================="

# --- 🚀 Update system ---
echo "🚀 Оновлення системи..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- 📦 Install Tailscale ---
if ! command -v tailscale >/dev/null 2>&1; then
    echo "📦 Встановлюю Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "✅ Tailscale вже встановлено."
fi

# --- 🔑 Connect to Tailnet ---
echo "🔑 Підключення до Tailnet..."
echo "💡 Відкрий посилання в браузері для авторизації та підтвердження входу."
sleep 2
sudo tailscale up --hostname="$HOSTNAME" $SSH_FLAG

# --- 📋 Summary ---
TAIL_IP=$(tailscale ip -4 2>/dev/null || true)
echo "✅ Пристрій додано до Tailnet!"
echo "----------------------------------------------"
echo "   Hostname: $HOSTNAME"
echo "   Tailnet IP: ${TAIL_IP:-невідомо (перевір: tailscale ip -4)}"
echo "----------------------------------------------"
echo "Перевірити статус: tailscale status"
echo "Зупинити: sudo tailscale down"