#!/bin/bash
source /scripts/ENV
ponto_montagem="/mnt/Orico01S"
#docker stop $(docker ps -a -q) && sleep 5
if grep -qs "$ponto_montagem" /proc/mounts; then
    exit 0
else
    echo "$(date) Tentativa de montagem $ponto_montagem" >> /tmp/montagem
    mount -a || curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" -d text="[⚠️ Atenção] $ponto_montagem não está acessível em $(hostname)" 2>&1 1>/dev/null ; exit 1
    exit 0
fi