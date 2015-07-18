import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BOARD)

class Buttons(object):
    def __init__(self, callback, debuglevel=1):
        self.pin_to_button = {}
        self.downtimes = {}
        self.callback = callback
        self.debuglevel = debuglevel
        import time
        self.now = time.time
        self.sleep = time.sleep

    def add(self, button, pin, callback=None):
        self.pin_to_button[pin] = button
        self.monitor_pin(pin, callback=callback)

    def monitor_pin(self, pin, callback=None, bouncetime=5):
        callback = callback or self.callback
        self.downtimes[pin] = None
        button = self.pin_to_button[pin]
        GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        def btn_down(signal, pin=pin, button=button):
            downtime = self.downtimes[pin]
            if downtime is not None:
                if downtime + 5 > self.now():
                    self.debug(5, "Ignoring down")
                    return
            self.downtimes[pin] = self.now()
            self.debug(3, "Down", pin, "-", signal)
        def btn_up(signal, pin=pin, button=button):
            downtime = self.downtimes[pin]
            if downtime is None:
                self.debug(5, "Ignoring up")
                return
            time = self.now() - downtime
            self.downtimes[pin] = None
            self.debug(3, "Up", pin)
            callback(button, time)
        def btn_event(signal, pin=pin, btn_down=btn_down, btn_up=btn_up):
            rawvalue = GPIO.input(pin)
            self.sleep(0.01)
            rawvalue2 = GPIO.input(pin)
            self.debug(4, "Raw", pin, "is", rawvalue, rawvalue2)
            if rawvalue:
                btn_up(signal)
            else:
                btn_down(signal)
        GPIO.add_event_detect(pin, GPIO.BOTH, callback=btn_event, bouncetime=bouncetime)

    def loop(self):
        try:
            while True:
                self.sleep(1)
        except KeyboardInterrupt:
            return

    def debug(self, level, *msgs):
        if level > self.debuglevel:
            return
        msg = u' '.join(map(unicode, msgs))
        print msg

def special_button_press(button, time):
    print "*** Pressed", button, "for", time

def button_press(button, time):
    print "Pressed", button, "for", time

buttons = Buttons(button_press, debuglevel=2)
buttons.add('1', 21, callback=special_button_press)
buttons.add('1p', 22)
buttons.add('2', 18)
buttons.add('2p', 19)
buttons.add('3', 12)
buttons.add('3p', 13)
buttons.add('4', 16)
buttons.add('4p', 15)
buttons.add('a', 7)
buttons.add('ap', 11)

buttons.loop()

