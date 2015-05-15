#!/bin/bash

service ntp stop
service triggerhappy stop
service dbus stop
sudo mount -o remount,size=256M /dev/shm

BUFSIZE=512
jackd  --realtime -p8 -t100000 -d alsa -dhw:1 -p${BUFSIZE} -n2 -H -M -z none -s&
# jack_bufsize $BUFSIZE
sleep 1.5
~/chuck --in1 Looper/looper-pedal.ck

killall jackd

