# Домашній Сервер
Корисні скрипти які можуть полегшити налаштування домашнього серверу



## 🚀 Встановлення агента Alloy (лише для систем на базі Debian)

Цей скрипт встановлює **Grafana Alloy** та налаштовує його для відправки логів до вашого Loki.

### ✅ Використання

Запустіть наступні команди на Debian-подібній системі (Ubuntu, Raspberry Pi OS, Proxmox CT тощо):

```bash
sudo apt update
sudo apt install -y curl
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ravado/homeserver/refs/heads/main/logs-and-monitoring/install_alloy.sh)"
```

### ⚠️ Важливо

🐧 Підтримуються лише системи на базі Debian
Протестовано на Ubuntu 22.04 та Raspberry Pi OS Bookworm.
Інші дистрибутиви можуть не працювати.

🌐 Під час встановлення потрібно буде ввести адресу вашого Loki
Наприклад: `http://192.168.91.100:3100/loki/api/v1/push`

🔑 Потрібні права sudo

📥 Необхідно мати встановлений curl
Встановіть його за потреби: sudo apt install curl