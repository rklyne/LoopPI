#!/bin/bash

service ntp stop
service triggerhappy stop
service dbus stop
sudo mount -o remount,size=256M /dev/shm

BUF_SIZE=256
BUF_NUM=4
JACK_OPTS=
JACK_ALSA_OPTS=
# Mono in:
JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -i1"
jackd  --realtime -P20 -p8 -t100000 ${JACK_OPTS} -d alsa -dhw:1 -p${BUF_SIZE} -n${BUF_NUM} -H -M ${JACK_ALSA_OPTS} -z none -s&
# jack_bufsize $BUF_SIZE
sleep 1
(
    sleep 1;
    sudo renice -20 `pidof chuck`;
    echo "niced chuck, pid ", `pidof chuck`
) &
~/chuck --in1 Looper/looper-pedal.ck

killall jackd

