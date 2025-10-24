# 🧰 Offsite Backup Setup Scripts

Цей набір скриптів допоможе швидко підготувати Raspberry Pi або будь-який Linux-пристрій як **офсайт-сховище для бекапів**.  
Скрипти виконують повну підготовку — від форматування диску до налаштування VPN-тунелю через **Tailscale** і NAT-проксі для доступу з локальної мережі.

---

## ⚙️ Скрипти

| № | Назва | Призначення |
|---|--------|--------------|
| **0_setup_disc.sh** | Форматує SSD / HDD, створює файлову систему `ext4`, монтує диск і додає запис у `/etc/fstab`. |
| **1_setup_rsync_service.sh** | Встановлює та налаштовує **rsyncd** для прийому бекапів, створює користувача й конфігурацію сервісу. |
| **2_setup_tailscale.sh** | Встановлює **Tailscale**, підключає пристрій до Tailnet і вмикає безпечний доступ по VPN. |
| **3_setup_lxc_router.sh** | Налаштовує **Tailscale-шлюз (NAT)** у LXC для переадресації запитів `rsync` у віддалену мережу. |

---

## 🚀 Послідовність виконання

### Якщо не встановлено то додайте curl пакет

```bash
sudo apt update && sudo apt install -y curl
```

### 1️⃣ Підготовка диску

Форматуємо диск і монтуємо його для зберігання бекапів:
```bash
bash <(curl -sL https://raw.githubusercontent.com/ravado/homeserver/main/offsite-backup/0_setup_disc.sh)
```

---

### 2️⃣ Встановлення rsync-сервісу

Налаштовуємо прийом бекапів через `rsyncd`:
```bash
bash <(curl -sL https://raw.githubusercontent.com/ravado/homeserver/main/offsite-backup/1_setup_rsync_service.sh)
```

---

### 3️⃣ Підключення до VPN (Tailscale)

Підключаємо пристрій до Tailnet, щоб отримати стабільний віддалений доступ:
```bash
bash <(curl -sL https://raw.githubusercontent.com/ravado/homeserver/main/offsite-backup/2_setup_tailscale.sh)
```

---

### 4️⃣ (Опціонально) Налаштування маршрутизатора у Proxmox

Якщо потрібно, щоб **локальна мережа бачила rsync-сервер через VPN**, запустіть цей скрипт у LXC-контейнері:
```bash
bash <(curl -sL https://raw.githubusercontent.com/ravado/homeserver/main/offsite-backup/3_setup_lxc_router.sh)
```

---

## 🧩 Корисні команди

| Завдання | Команда |
|-----------|----------|
| Перевірити змонтовані диски | `lsblk` |
| Перевірити Tailscale-статус | `tailscale status` |
| Дізнатися IP-адресу | `tailscale ip -4` |
| Перевірити доступність rsync | `nc -zv <ip> 873` |
| Переглянути NAT-правила | `sudo iptables -t nat -L -n -v` |

---

## 🧠 Примітки

- Скрипти перевіряють наявність прав `sudo` і не змінюють системні файли без підтвердження.  
- Якщо пристрій буде перевезено в інше місце, просто підключіть його до Wi-Fi — **Tailscale автоматично відновить з’єднання**.  
- Для LXC у Proxmox додайте до `/etc/pve/lxc/<ID>.conf`:
  ```bash
  lxc.cgroup2.devices.allow: c 10:200 rwm
  lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
  ```

---

📺 **Автор:** [Домашній Сервер](https://www.youtube.com/@homeserver)  
💬 **Проєкт:** https://github.com/ravado/homeserver  