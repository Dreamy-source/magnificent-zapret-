# magnificent

DPI обход на Linux через nfqws с автоочисткой, проверкой зависимостей и меню.

## Возможности
- 🛡️ Обход DPI через nfqueue (nfqws)
- 📋 Поддержка hostlist (149 000+ доменов)
- 🔄 Множественные стратегии обхода (QUIC, TCP, UDP)
- 🧹 Автоочистка nftables и очередей перед запуском
- 📦 Автоустановка зависимостей (nftables, yay, nfqws)
- 🎨 Цветное меню с навигацией

## Быстрый старт
```bash
sudo pacman -S --noconfirm python
python3 ini.py
./runner.sh
# после того, как попадете в меню, выберите второй выбор (2) для установки всех зависимостей
```

## Требования
- Linux с nfnetlink_queue
- nfqws
- nftables
