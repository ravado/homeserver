#!/usr/bin/env bash
set -euo pipefail

echo "🔧 === Встановлення та налаштування rsyncd ==="

# --- 🧩 Збір базових даних ---
read -rp "👤 Введи ім'я користувача для rsync [backuper]: " USER
USER=${USER:-backuper}

read -rsp "🔑 Введи пароль для користувача $USER (обов’язково): " PASS
echo
if [[ -z "$PASS" ]]; then
    echo "❌ Пароль не може бути порожнім."
    exit 1
fi

read -rp "📂 Вкажи шлях до каталогу для бекапів [/mnt/backups]: " MOUNT_POINT
MOUNT_POINT=${MOUNT_POINT:-/mnt/backups}

# --- 👤 Створюємо користувача ---
if ! id "$USER" >/dev/null 2>&1; then
    echo "👤 Створюю користувача $USER..."
    sudo adduser --disabled-password --gecos "" "$USER"
else
    echo "✅ Користувач $USER вже існує."
fi

# --- 📦 Встановлення rsync ---
echo "📦 Встановлюю rsync..."
sudo apt-get update -y && sudo apt-get install -y rsync

# --- ⚙️ Підготовка каталогу ---
sudo mkdir -p "$MOUNT_POINT"
sudo chown -R "$USER:$USER" "$MOUNT_POINT"

# --- 🧾 Конфігурація rsyncd ---
echo "📝 Створюю /etc/rsyncd.conf..."
sudo tee /etc/rsyncd.conf >/dev/null <<EOF
uid = $USER
gid = $USER
use chroot = no
max connections = 2
timeout = 300

[backup]
   path = $MOUNT_POINT
   comment = Backup module
   read only = false
   auth users = $USER
   secrets file = /etc/rsyncd.secrets
EOF

# --- 🔑 Secrets ---
echo "🔑 Створюю /etc/rsyncd.secrets..."
echo "$USER:$PASS" | sudo tee /etc/rsyncd.secrets >/dev/null
sudo chmod 600 /etc/rsyncd.secrets
sudo chown root:root /etc/rsyncd.secrets

# --- 🚀 Запуск і автозапуск ---
echo "🚀 Увімкнення rsync як сервісу..."
sudo systemctl enable rsync
sudo systemctl restart rsync

# --- 🧪 Підсумок ---
echo "✅ Rsyncd налаштований і запущений!"
echo "----------------------------------------------"
echo "   🔌 Порт: 873"
echo "   📦 Модуль: [backup]"
echo "   📂 Шлях: $MOUNT_POINT"
echo "   👤 Користувач: $USER"
echo "----------------------------------------------"
echo "🧪 Для перевірки з іншого пристрою виконай:"
echo "   rsync ${USER}@<IP_адреса>::backup"
echo
echo "📜 Статус сервісу можна перевірити командою:"
echo "   sudo systemctl status rsync"