#!/bin/bash

# Some system prep
sudo service ntp stop
sudo service triggerhappy stop
sudo service cron stop
sudo mount -o remount,size=512M /dev/shm
for CPU in 0 1 2 3; do
    echo -n "performance" | sudo tee /sys/devices/system/cpu/cpu${CPU}/cpufreq/scaling_governor ;
done

# JACKD / CHUCK config vars
RATE=44100
BUF_SIZE=256
BUF_NUM=3
JACK_OPTS="-m "
JACK_ALSA_OPTS="-S -z shaped -D "
# Mono in:
JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -i1"


# START JACKD

export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
jackd  --realtime -P1 -p8 -t100000 ${JACK_OPTS} -d alsa -dhw:1 -p${BUF_SIZE} -n${BUF_NUM} -H -M ${JACK_ALSA_OPTS} -s --rate ${RATE} &
# jack_bufsize $BUF_SIZE


# START CHUCK

sleep 1
(
    sleep 1;
    sudo renice -20 `pidof chuck`;
    echo "niced chuck, pid ", `pidof chuck`
) &

CHUCK_OPTS=" --in1 --srate:${RATE}  --bufnum:${BUF_NUM} --adaptive:${BUF_SIZE}"
~/chuck ${CHUCK_OPTS} Looper/looper-pedal.ck

killall jackd


