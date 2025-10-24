#!/usr/bin/env bash
set -euo pipefail

echo "💾 === Налаштування диску для офсайт-бекапу ==="

read -rp "📂 Введи точку монтування SSD [/mnt/backupdisk]: " MOUNT_POINT
MOUNT_POINT=${MOUNT_POINT:-/mnt/backupdisk}

# --- 🔍 Знаходимо зовнішній диск ---
DISK=$(lsblk -ndo NAME,TRAN | awk '$2=="usb"{print "/dev/"$1; exit}')
if [[ -z "${DISK}" ]]; then
    echo "❌ Не знайдено USB-диск. Підключи SSD і повтори."
    exit 1
fi
if [[ "$DISK" == *mmcblk0* ]]; then
    echo "🚫 Це SD-карта системи ($DISK). Скасовано, щоб не стерти ОС."
    exit 1
fi
echo "✅ Знайдено диск: $DISK"

# --- ⚙️ Пропозиція форматування ---
FSTYPE=$(lsblk -no FSTYPE "$DISK" | head -n1)
if [[ -n "$FSTYPE" ]]; then
    echo "ℹ️  На диску вже є файловa система: $FSTYPE"
else
    echo "⚠️  На диску $DISK немає файлової системи."
fi

read -rp "Хочеш відформатувати диск у ext4 (стерти всі дані)? (yes/NO): " confirm
if [[ "${confirm,,}" == "yes" ]]; then
    echo "🧹 Форматую $DISK у ext4..."
    sudo umount -f "${DISK}"* || true
    sudo parted -s "$DISK" mklabel gpt mkpart primary ext4 0% 100%
    sudo mkfs.ext4 -F -L BACKUPDISK "${DISK}1"
    sleep 2
    DISK="${DISK}1"
    echo "✅ Форматування завершено."
else
    echo "🚫 Форматування пропущено."
fi

# --- 📎 Отримуємо UUID ---
UUID=$(sudo blkid -s UUID -o value "$DISK")
if [[ -z "$UUID" ]]; then
    echo "❌ Не вдалося отримати UUID. Можливо, диск не відформатовано?"
    exit 1
fi
echo "📎 UUID диску: $UUID"

sudo mkdir -p "$MOUNT_POINT"
sudo sed -i "/$UUID/d" /etc/fstab
echo "UUID=$UUID  $MOUNT_POINT  ext4  defaults,noatime,nofail 0 0" | sudo tee -a /etc/fstab

echo "🔄 Монтуємо диск..."
sudo mount -a

sudo chmod 755 "$MOUNT_POINT"

echo "✅ Готово!"
echo "   - Диск змонтовано до: $MOUNT_POINT"
echo "   - UUID: $UUID"