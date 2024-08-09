#!/bin/bash

set -e  # Para o script se qualquer comando falhar

# Variáveis
SOURCE_PATH="/containers"
DEST_PATH="/mnt/Orico01S/Django/Variados/Backup"
MOUNT_POINT="/mnt/Orico01S"
RESTIC_PATH="/mnt/ResticBackup/containers"
PASSWORD_FILE="/scripts/password"
LOG_FILE="/tmp/bkpcontainers"
VNSTAT_SOURCE="/var/lib/vnstat"
VNSTAT_DEST="$DEST_PATH/vnstat"
MAIL_RECIPIENT="modengo"

function check_command {
    command -v "$1" &>/dev/null || { echo "Erro: comando $1 não encontrado."; exit 1; }
}

function manage_docker {
    local action=$1
    systemctl "$action" docker
    sleep 5
}

check_command rsync
check_command restic
check_command systemctl

manage_docker stop

# Verificar se o ponto de montagem está acessível
if grep -qs "$MOUNT_POINT" /proc/mounts; then
    # Sincronizar os containers e vnstat
    rsync -Cravztp "$SOURCE_PATH" "$DEST_PATH" | tee -a "$LOG_FILE"
    restic -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" backup "$SOURCE_PATH" | tee -a "$LOG_FILE"
    date +"%H:%M:%S - %d/%m/%Y" >> "$LOG_FILE"
    
    # Sincronizar os dados do vnstat
    rsync -Cravztp "$VNSTAT_SOURCE" "$VNSTAT_DEST" | tee -a "$LOG_FILE"
    date +"%H:%M:%S - %d/%m/%Y" >> "$LOG_FILE"
else
    echo "A pasta não está acessível."
    echo "Assunto: Ponto de montagem $MOUNT_POINT nao montado" | /usr/bin/mail -s "Ponto de montagem $MOUNT_POINT não está pronto" "$MAIL_RECIPIENT"
    restic -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" backup "$SOURCE_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

manage_docker start
