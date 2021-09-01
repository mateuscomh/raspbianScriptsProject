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
import time
import sys 

import Adafruit_GPIO.SPI as SPI 
import Adafruit_SSD1306
import signal

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont

import subprocess

# Raspberry Pi pin configuration:
RST = None     # on the PiOLED this pin isnt used
# Note the following are only used with SPI:
DC = 23
SPI_PORT = 0 
SPI_DEVICE = 0 

# 128x32 display with hardware I2C:
disp = Adafruit_SSD1306.SSD1306_128_32(rst=RST)

# Initialize library.
disp.begin()

# Clear display.
disp.clear()
disp.display()

# Create blank image for drawing.
# Make sure to create image with mode '1' for 1-bit color.
width = disp.width
height = disp.height
image = Image.new('1', (width, height))

# Get drawing object to draw on image.
draw = ImageDraw.Draw(image)

# Draw a black filled box to clear the image.
draw.rectangle((0,0,width,height), outline=0, fill=0)

# Draw some shapes.
# First define some constants to allow easy resizing of shapes.
padding = -2
top = padding
bottom = height-padding
# Move left to right keeping track of the current x position for drawing shapes.
x = 0

# Load default font.
font = ImageFont.load_default()

#Função para interrupção de script e limpar a tela pós shutdown
def trap_python(signum, stack):
    print("Recebido Control-C")
    disp.clear()
    disp.display()
    sys.exit(0)

while True:
    #Chamada na função em caso de interrupção
    signal.signal(signal.SIGINT, trap_python)
    signal.signal(signal.SIGHUP, trap_python)
    signal.signal(signal.SIGTERM, trap_python)

    #Desenhando um retangulo para receber conteudo
    draw.rectangle((0,0,width,height), outline=0, fill=0)

    #cmd = "hostname -I | cut -d\' \' -f1"
    cmd = "curl -s ifconfig.me"
    IP = subprocess.check_output(cmd, shell = True )
    cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: %.2f\", $(NF-2)}'"
    CPU = subprocess.check_output(cmd, shell = True )
    cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
    MemUsage = subprocess.check_output(cmd, shell = True )
    cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
    Disk = subprocess.check_output(cmd, shell = True )

    #Escrevendo as 4 linhas da primeira sessao
    draw.text((x, top),       IP,  font=font, fill=255)
    draw.text((x, top+8),     CPU, font=font, fill=255)
    draw.text((x, top+16),    MemUsage,  font=font, fill=255)
    draw.text((x, top+25),    Disk,  font=font, fill=255)

    #Exibindo as primeira sessao
    disp.image(image)
    disp.display()
    time.sleep(10)

    #Limpa tela para segunda sessao
    draw.rectangle((0,0,width,height), outline=0, fill=0)

    #Escrevendo as 4 linhas da segunda sessao
    cmd = "hostname"
    Hname = subprocess.check_output(cmd, shell = True)
    cmd = "sensors | grep temp | awk '{print \" Temp: \" $2}' | cut -c2-12"
    Temp = subprocess.check_output(cmd, shell = True)
    cmd = "uptime | awk '{printf \"Uptime: \"$3}'"
    Utime = subprocess.check_output(cmd, shell = True)
    cmd = "date +%d/%m/%y_%H:%M"
    Date= subprocess.check_output(cmd, shell = True)

    #Exibindo a segunda sessao
    draw.text((x, top),       Hname,  font=font, fill=255)
    draw.text((x, top+8),     Temp, font=font, fill=255)
    draw.text((x, top+16),    Utime,  font=font, fill=255)
    draw.text((x, top+25),    Date,  font=font, fill=255)

    disp.image(image)
    disp.display()
    time.sleep(10)
    
