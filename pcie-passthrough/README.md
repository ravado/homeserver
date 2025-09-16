# fix_vfio_dupplicates.sh

Скрипт для автоматичного прибирання дублікатів у файлі **`/etc/modprobe.d/vfio.conf`**.  
Допомагає у випадках, коли [утиліта](https://github.com/Danilop95/Proxmox-Enhanced-Configuration-Utility) додає повторювані `vfio-pci ids` записи, що заважає коректному завантаженню модулів VFIO.

## Як працює
- Створює резервну копію файлу `vfio.conf`
- Знаходить усі `ids=` параметри
- Нормалізує регістр, прибирає дублікати
- Перезаписує рядок з чистим списком пристроїв

## Використання

1. Запустіть в консолі Proxmox:

```bash
bash <(curl -sL https://raw.githubusercontent.com/ravado/homeserver/refs/heads/main/pcie-passthrough/fix_vfio_dupplicates.sh)
```

2. Після цього перезавантажте хост:

```bash
reboot
```

3.	Перевірте, що модулі VFIO завантажуються без помилок:

```bash
dmesg | grep vfio
```