#!/usr/bin/env bash
# ============================================
# 🌐 Tailscale Gateway + NAT for rsync
# ============================================

set -euo pipefail

# === Privilege detection ===
if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
elif [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  echo "❌ Цей скрипт потрібно запускати з правами root або через sudo."
  exit 1
fi

# ============================================
# 🧠 Введення IP віддаленого пристрою
# ============================================

read -e -p "🌐 Введи Tailscale IP віддаленого пристрою (починається з 100.): " -i "100." REMOTE_IP

if [[ ! "$REMOTE_IP" =~ ^100\. ]]; then
  echo "❌ Некоректна IP-адреса. Tailscale IPv4 завжди починаються з 100."
  exit 1
fi

RSYNC_PORT=873
LXC_IP=$(hostname -I | awk '{print $1}')

# ============================================
# 📦 Залежності
# ============================================

echo "🚀 Оновлюю систему..."
$SUDO apt-get update -y && $SUDO apt-get upgrade -y

echo "📦 Встановлюю curl і iptables-persistent..."
$SUDO apt-get install -y curl iptables-persistent net-tools

# ============================================
# 🌀 Встановлення Tailscale
# ============================================

if ! command -v tailscale >/dev/null 2>&1; then
  echo "📦 Встановлюю Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | $SUDO bash
else
  echo "✅ Tailscale вже встановлено."
fi

# ============================================
# 🛠️ Увімкнення IP forwarding
# ============================================

echo "🛠️ Вмикаю IP forwarding..."
$SUDO tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

$SUDO sysctl --system >/dev/null

# ============================================
# 🔗 Підключення до Tailnet
# ============================================

if ! tailscale status >/dev/null 2>&1; then
  echo "🔑 Підключення цього вузла до Tailnet..."
  echo "💡 Відкрий посилання, що з’явиться нижче, у браузері для авторизації."
  $SUDO tailscale up
else
  echo "✅ Вузол уже підключений до Tailnet."
fi

echo "🌍 Поточна Tailscale IP-адреса:"
tailscale ip -4

# ============================================
# 🧱 Налаштування NAT для rsync
# ============================================

echo "🧹 Очищаю старі NAT-правила для порту ${RSYNC_PORT}..."
$SUDO iptables -t nat -D PREROUTING -p tcp --dport ${RSYNC_PORT} -j DNAT --to-destination ${REMOTE_IP}:${RSYNC_PORT} 2>/dev/null || true
$SUDO iptables -t nat -D POSTROUTING -p tcp -d ${REMOTE_IP} --dport ${RSYNC_PORT} -j MASQUERADE 2>/dev/null || true

echo "📡 Додаю DNAT правило (перенаправлення ${RSYNC_PORT} → ${REMOTE_IP})..."
$SUDO iptables -t nat -A PREROUTING -p tcp --dport ${RSYNC_PORT} -j DNAT --to-destination ${REMOTE_IP}:${RSYNC_PORT}

echo "🔁 Додаю MASQUERADE правило (зворотний трафік)..."
$SUDO iptables -t nat -A POSTROUTING -p tcp -d ${REMOTE_IP} --dport ${RSYNC_PORT} -j MASQUERADE

echo "💾 Зберігаю iptables конфігурацію..."
$SUDO netfilter-persistent save >/dev/null

# ============================================
# ✅ Підсумок
# ============================================

echo
echo "✅ Готово! Цей LXC тепер працює як Tailscale шлюз із NAT-проксі для rsync."
echo "----------------------------------------------"
echo "🔍 Перевірити статус Tailscale:   tailscale status"
echo "🔍 Перевірити NAT правила:        ${SUDO} iptables -t nat -L -n -v"
echo "🔍 Перевірити IP forwarding:      sysctl net.ipv4.ip_forward"
echo "🔍 Перевірити доступність rsync:  nc -zv ${LXC_IP} 873"
echo "----------------------------------------------"

cat <<'NOTE'

📋 Нагадування для LXC у Proxmox:
Додай у /etc/pve/lxc/<ID>.conf (якщо ще немає):

  lxc.cgroup2.devices.allow: c 10:200 rwm
  lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file

NOTE