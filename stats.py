#!/usr/bin/env python3

# Copyright (c) 2017 Adafruit Industries
# Author: Tony DiCola & James DeVito
# Modified : Matheus Martins
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Necessário importar template do display em https://github.com/adafruit/Adafruit_SSD1306

# Importando as bibliotecas
import time
import sys
import signal
import datetime

import Adafruit_GPIO.SPI as SPI
import Adafruit_SSD1306

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont

import subprocess

# Configuração dos pinos da Raspberry Pi
RST = None
# Apenas no modo SPI para ser usado
DC = 23
SPI_PORT = 0
SPI_DEVICE = 0

disp = Adafruit_SSD1306.SSD1306_128_32(rst=RST)

# Inicializando a biblioteca
disp.begin()

# Limpando a tela
disp.clear()
disp.display()

width = disp.width
height = disp.height
image = Image.new('1', (width, height))

# "Limpando" a tela preenchendo com fundo preto
draw = ImageDraw.Draw(image)
draw.rectangle((0,0,width,height), outline=0, fill=0)

# Preparando a tela
padding = -2
top = padding
bottom = height-padding
# Move o sinalizador para o canto esquerdo para iniciar escrita
x = 0

# Carregando as fontes para projeto
## Outras fontes podem ser obtidas em http://www.datafont.com/bitmap.php
font = ImageFont.load_default()
font2 = ImageFont.truetype('digital-7.mono.ttf', 24)

# Informacoes de hora e data
dateString = '%d %B %Y'
timeString = '%H:%M'

# Função de interrupção para limpeza da tela (trap)
def kill_signal(signum, frame):
    print("Recebido Control-C")
    disp.clear()
    disp.display()
    sys.exit(0)

# Código em loop com as telas de hora,sistema e status
# Em breve novas func.
try:
    while True:
        # Sinais de interrupção chamadno a função kill_signal
        signal.signal(signal.SIGINT, kill_signal)
        signal.signal(signal.SIGHUP, kill_signal)
        signal.signal(signal.SIGTERM, kill_signal)

        # Atribuição de hora e data
        strDate = datetime.datetime.now().strftime(dateString)
        result  = datetime.datetime.now().strftime(timeString)

        # "Limpando" a tela preenchendo com fundo preto
        draw.rectangle((0,0,width,height), outline=0, fill=0)

        # Texto de data em duas linhas.
        draw.text((x+15,top),strDate, font=font,fill=255)
        draw.text((x+35, top+14), result,  font=font2, fill=255)
        draw.line((0, top+12, 127, top+12), fill=100)

        # Exibindo a imagem com timer.
        disp.image(image)
        disp.display()
        time.sleep(35)

        draw.rectangle((0,0,width,height), outline=0, fill=0)

        #cmd = "hostname -I | cut -d\' \' -f1"
        cmd = "curl -s ifconfig.me"
        IP = subprocess.check_output(cmd, shell = True )
        #cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: %.2f\", $(NF-2)}'"
        cmd = "uptime  | grep -o 'load.*' | sed s/\ average// | sed s/,\ /\|/g"
        CPU = subprocess.check_output(cmd, shell = True )
        cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
        MemUsage = subprocess.check_output(cmd, shell = True )
        cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
        Disk = subprocess.check_output(cmd, shell = True )

        # Escrevendo as 4 linhas da primeira sessao
        draw.text((x, top),       IP,  font=font, fill=255)
        draw.text((x, top+8),     CPU, font=font, fill=255)
        draw.text((x, top+16),    MemUsage,  font=font, fill=255)
        draw.text((x, top+25),    Disk,  font=font, fill=255)

        # Exibindo as primeira sessao
        disp.image(image)
        disp.display()
        time.sleep(10)

        # Limpa tela para segunda sessao
        draw.rectangle((0,0,width,height), outline=0, fill=0)

        # Escrevendo as 4 linhas da segunda sessao
        cmd = "echo Hostname: $(hostname)"
        Hname = subprocess.check_output(cmd, shell = True)
        cmd = "sensors | grep temp | awk '{print \" Temp: \" $2}' | cut -c2-12"
        Temp = subprocess.check_output(cmd, shell = True)
        cmd = "uptime | awk -F' ' '{print \"Uptime: \" $3$4}' | sed s/,//"
        Utime = subprocess.check_output(cmd, shell = True)
        cmd = "echo Data: $(date +%d/%m/%y_%H:%M)"
        Date= subprocess.check_output(cmd, shell = True)

        # Exibindo as info da proxima tela
        draw.text((x, top),       Hname,  font=font, fill=255)
        draw.text((x, top+8),     Temp, font=font, fill=255)
        draw.text((x, top+16),    Utime,  font=font, fill=255)
        draw.text((x, top+25),    Date,  font=font, fill=255)

        disp.image(image)
        disp.display()
        time.sleep(10)

except (KeyboardInterrupt, BrokenPipeError, SystemExit): # Se houver interrupcao ou erro no while sai do programa limpando o display
    print("Display limpo!")
    GPIO.cleanup()
