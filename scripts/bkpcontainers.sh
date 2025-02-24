#!/bin/bash

source /scripts/ENV
midia_externa="/mnt/Dados500G/Backups"
check_file="/mnt/Dados500G/checkpoint.tmp"
restic_local="/mnt/ResticBlade"
#restic_pen_morpheus="/mnt/ResticBackup/blade/"
password_file="/scripts/password"
email="blade"
backup_dir="/mnt/Data/containers"
backup_dir1="/mnt/Data/Obsidian"
log_file="/tmp/syncbackup"

# Verificar se o ponto de montagem está acessível
if [ -f $check_file ]; then
# Backup de midia com Restic
  date +"%H:%M:%S - %d/%m/%Y" | tee "$log_file"
  restic -r "$restic_local" --verbose --password-file "$password_file" backup "$backup_dir" | tee -a $log_file
  restic -r "$restic_local" --password-file "$password_file" check | tee -a "$log_file"
  sleep 5

  # Se o ponto de montagem estiver acessível, parar o Docker
  systemctl stop docker

  # rsync restic
  rsync -Cravz "$restic_local" "$media_externa/restic"
  if [[ $? -eq 0 ]]; then
    restic forget --password-file "$password_file" --keep-last 10 -r "$restic_local" | tee -a "$log_file"
    restic prune -r "$restic_local" --password-file "$password_file" | tee -a "$log_file"
  fi

  # rsync containers
  rsync -Crazv "$backup_dir" "$backup_dir1" "$midia_externa/containers/containersBlade" | tee -a $log_file
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="[✅ Done] Backup realizado em: $midia_externa no $hostname "
  date +"%H:%M:%S - %d/%m/%Y" | tee -a $log_file
  # Executar backup vnstat
  rsync -Cravz -e /var/lib/vnstat "$midia_externa/vnstatBlade" | tee /tmp/bkpvnstat
  date +"%H:%M:%S - %d/%m/%Y" >> /tmp/bkpvnstat
  sleep 5

  # Verificar se o rsync foi bem-sucedido
  if [[ $? -ne 0 ]]; then
    # Enviar e-mail se o rsync falhar
    echo -e "$(date +'%d/%m/%Y %H:%M') - Assunto: Ponto de montagem $midia_externa nao montado" | /usr/bin/mail -s "Ponto de montagem não está pronto" "$email"
    sleep 5

    # Reiniciar o Docker
    systemctl start docker
    docker ps
  fi

else
  # Enviar e-mail se o ponto de montagem remoto não estiver acessível
  echo -e "$(date +'%d/%m/%Y %H:%M') - Assunto: Ponto de montagem $midia_externa nao acessível" | /usr/bin/mail -s "Ponto de montagem não está acessível. Backup Local feito" "$email" | tee "$log_file"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="[🔴 Down] Ponto de montagem $midia_externa nao acessivel. Backup Local"
  date +"%H:%M:%S - %d/%m/%Y" | tee -a "$log_file"
  restic -r "$restic_local" --verbose --password-file "$password_file" backup "$backup_dir" | tee -a "$log_file"
fi

# Reiniciar o Docker
systemctl start docker
docker ps

exit
