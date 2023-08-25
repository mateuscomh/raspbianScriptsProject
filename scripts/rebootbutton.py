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