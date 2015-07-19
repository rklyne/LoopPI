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

class ButtonAction(object):
    def __init__(self, *args, **kwargs):
        long_press_time = kwargs.pop('long_press_time', 1)
        self.long_press_time = long_press_time
        self.pin = None
        self.init(*args, **kwargs)

    def init(self):
        pass

    def __call__(self, pin, time):
        self.pin = pin
        return self.handle_press(time)

    def handle_press(self, time):
        print "handling press for", time
        if time > self.long_press_time:
            result = self.long_press()
            if result is not NotImplemented:
                return result
            print "long_press tried but not implemented"
        return self.press()

    def has_long_press(self):
        return self.long_press is not ButtonAction.long_press

    def long_press(self):
        print "default longpress"
        return NotImplemented

    def press(self):
        print "default press"
        return NotImplemented

    def send(self, path, *args):
        import liblo
        liblo.send(
                'osc.udp://localhost:3000'+path,
                liblo.Message(path, *args))


class RecordButton(ButtonAction):
    def init(self, recorder):
        self.recorder = recorder

    def press(self):
        self.send('/recording', self.recorder)
        print "record pressed", self.recorder

class PauseButton(ButtonAction):
    def init(self, recorder):
        self.recorder = recorder

    def press(self):
        self.send('/pause', self.recorder)
        print "pause pressed", self.recorder

    def long_press(self):
        self.send('/delete', self.recorder)
        print "delete pressed", self.recorder

def special_button_press(button, time):
    print "*** Pressed", button, "for", time

def button_press(button, time):
    print "Pressed", button, "for", time

ALL = -1
buttons = Buttons(button_press, debuglevel=2)
buttons.add('1', 21, callback=RecordButton(1))
buttons.add('1p', 22, callback=PauseButton(1))
buttons.add('2', 18, callback=RecordButton(2))
buttons.add('2p', 19, callback=PauseButton(2))
buttons.add('3', 12, callback=RecordButton(3))
buttons.add('3p', 13, callback=PauseButton(3))
buttons.add('4', 16, callback=RecordButton(4))
buttons.add('4p', 15, callback=PauseButton(4))
buttons.add('all',  7, callback=RecordButton(ALL))
buttons.add('allp', 11, callback=PauseButton(ALL))

buttons.loop()

