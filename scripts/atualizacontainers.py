#!/usr/bin/env python3

import RPi.GPIO as GPIO
import time
import os

GPIO.setmode(GPIO.BCM)
GPIO.setup(7, GPIO.IN, pull_up_down=GPIO.PUD_UP)

def Shutdown(channel):
    os.system("wall shuting down in 5 secs...")
    time.sleep(5)
    os.system("sudo shutdown -r now")

GPIO.add_event_detect(7, GPIO.FALLING, callback=Shutdown, bouncetime=2000)
while 1:
    time.sleep(1)
➜  /scripts cat atualizaContainers.sh
#!/usr/bin/env bash

# Atualizar as imagens
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -L1 docker pull

# Listar todos os containers em execução
containers=$(docker ps -q)

# Para cada container em execução
for container in $containers; do
  # Verificar se a imagem do container foi atualizada
  image_id=$(docker inspect -f '{{.Image}}' $container)
  image_name=$(docker image inspect -f '{{.RepoDigests}}' $image_id | sed -n 's/.*\(sha256:[0-9a-f]*\).*/\1/p')

  if [[ -z "$image_name" ]]; then
    # Se a imagem não possui um nome de repositório (pode ser uma imagem local), pule-a
    continue
  fi

  # Verificar se a imagem foi atualizada
  if [[ $(docker image inspect -f '{{.RepoDigests}}' $image_name) != *"$image_name"* ]]; then
    echo "Reiniciando o container $container, imagem foi atualizada."
    docker restart $container
  fi
done
