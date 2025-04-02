#!/bin/bash
source /scripts/ENV
ponto_montagem="/mnt/ResticBackup"
if [ -d "$ponto_montagem" ] && ls "$ponto_montagem/checkpointMorpheus.tmp" > /dev/null 2>&1; then
    exit 0
else
    echo "$(date) Tentativa de montagem $ponto_montagem" >> /tmp/montagem
    mount -a
    ls "$ponto_montagem/Django" && echo "$(date) montagem ok" || curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="[⚠️ Atenção] $ponto_montagem não está acessível em $(hostname)" 2>&1 1>/dev/null
    exit 0
fi
