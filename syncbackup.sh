#!/bin/bash

#set -e  # Parar o script se qualquer comando falhar

source /scripts/ENV

# Variáveis
SOURCE_PATH="/containers"
MOUNT_POINT="/mnt/Orico01S"
RESTIC_PATH="/mnt/ResticBackup/containers"
PASSWORD_FILE="/scripts/password"
LOG_FILE="/tmp/bkpcontainers"
VNSTAT_SOURCE="/var/lib/vnstat"
MAIL_RECIPIENT="modengo"
REMOTE_PORT="10025"
REMOTE_PATH="/mnt/Dados500G"
REMOTE_HOST="192.168.2.186"
REMOTE_USER="blade"
# Função para verificar se um comando existe
function check_command {
    command -v "$1" &>/dev/null || { echo "Erro: comando $1 não encontrado."; exit 1; }
}

# Verificar se os comandos essenciais estão disponíveis
check_command rsync
check_command restic
check_command systemctl

systemctl stop docker

# Verificar se o ponto de montagem está acessível
ssh -p "$REMOTE_PORT" $REMOTE_USER@"$REMOTE_HOST" test -e "$REMOTE_PATH/checkpoint.tmp"
exit_code=$?
if [ $exit_code -eq 0 ]; then
  date +"%H:%M:%S - %d/%m/%Y" | tee -a "$LOG_FILE"
  # Sincronizar os containers
  rsync -Cravzp -e "ssh -p $REMOTE_PORT" "$SOURCE_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/Backups/containers/containersMorpheus" | tee "$LOG_FILE"

 # Backup restic Pendrive
  restic -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" backup "$SOURCE_PATH" | tee -a "$LOG_FILE"
  restic -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" check | tee -a "$LOG_FILE"
  restic forget --password-file "$PASSWORD_FILE" --keep-last 10 -r "$RESTIC_PATH" | tee -a "$LOG_FILE"
  restic prune -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" | tee -a "$LOG_FILE"

 # Backup restic HD remoto
  restic -r "sftp://$REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT/$REMOTE_PATH/Backups/containers/containersMorpheus" --password-file "$PASSWORD_FILE" backup "$RESTIC_PATH" | tee -a "$LOG_FILE"
  restic -r "sftp://$REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT/$REMOTE_PATH/Backups/containers/containersMorpheus" --password-file "$PASSWORD_FILE" check | tee -a "$LOG_FILE"
  restic -r "sftp://$REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT/$REMOTE_PATH/Backups/containers/containersMorpheus" --password-file "$PASSWORD_FILE" forget --keep-last 30 --prune | tee -a "$LOG_FILE"

  # Sincronizar os dados do vnstat
  rsync -Cravzp "$VNSTAT_SOURCE" /mnt/vnstatMorpheus | tee -a "$LOG_FILE"
  rsync -Cravzp -e "ssh -p $REMOTE_PORT" "$VNSTAT_SOURCE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/Backups/vnstatMorpheus/" | tee -a "$LOG_FILE"
  date +"%H:%M:%S - %d/%m/%Y" | tee -a "$LOG_FILE"
else
  # Tratamento quando o arquivo não existe ou outro erro não relacionado a conexão ocorre
  echo "A pasta não está acessível ou arquivo não existe." | tee -a "$LOG_FILE"
  date +"%H:%M:%S - %d/%m/%Y" | tee -a "$LOG_FILE"
  echo "Assunto: Ponto de montagem $REMOTE_PATH em $REMOTE_HOST não está acessível" | /usr/bin/mail -s "Ponto de montagem não acessível" "$MAIL_RECIPIENT"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="[🔴 Down] Conexão remota para $REMOTE_HOST em $hostname não acessível"

  # Backup restic local (fallback)
  restic -r "$SOURCE_PATH" "$RESTIC_PATH" --password-file "$PASSWORD_FILE" backup | tee -a "$LOG_FILE"
  restic -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" check | tee -a "$LOG_FILE"
  restic prune -r "$RESTIC_PATH" --password-file "$PASSWORD_FILE" | tee -a "$LOG_FILE"
fi

date +"%H:%M:%S - %d/%m/%Y" | tee -a "$LOG_FILE"
# Iniciar Docker
systemctl start docker
