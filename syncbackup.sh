#!/bin/bash
ponto_montagem="/mnt/Orico01S"
#docker stop $(docker ps -a -q) && sleep 5
if grep -qs "$ponto_montagem" /proc/mounts; then
    systemctl stop docker && sleep 5
    rsync -Cravztp /ORIG /DEST
    sleep 5
    rsync -Cravztp /ORIGvnsta /DEST
    sleep 15
    systemctl start docker
else
    echo "A pasta não está acessível."
    echo "Assunto: Ponto de montagem $ponto_montagem nao montado" | /usr/bin/mail -s "Ponto de montagem não está pronto" $USER
    exit 1
fi
