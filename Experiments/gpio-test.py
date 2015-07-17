import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BOARD)

def monitor_pin(pin):
    GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    def my_callback(signal, pin=pin):
        print "Detected", pin
    GPIO.add_event_detect(pin, GPIO.FALLING, callback=my_callback, bouncetime=50)

pins = 0
for pin in [
        7,
        11,
        12,
        13,
        15,
        16,
        18,
        19,
        21,
        22,
        23,
        24,
        26,
        29,
        31,
        32,
        33,
        35,
        36,
        37,
        38,
        40,
        ]:
    pins += 1
    monitor_pin(pin)

print "Monitoring", pins, "pins"

import time
time.sleep(30)

