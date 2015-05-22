#!/bin/bash

# Some system prep
sudo service ntp stop
sudo service triggerhappy stop
sudo service cron stop
sudo service dphys-swapfile stop
sudo mount -o remount,size=512M /dev/shm
for CPU in 0 1 2 3; do
    echo -n "performance" | sudo tee /sys/devices/system/cpu/cpu${CPU}/cpufreq/scaling_governor ;
done
. fix_irq_prio.sh


# JACKD / CHUCK config vars
JACKD_PRIO=1
CHUCK_PRIO=2
RATE=44100
RATE=48000
BUF_SIZE=96
BUF_NUM=3
JACK_OPTS=" -P1 "
JACK_ALSA_OPTS="-S -z none -D "
# Mono in:
# JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -i1"


# START JACKD

export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
jackd  --realtime -p8 -t100000 ${JACK_OPTS} -d alsa -dhw:1 -p${BUF_SIZE} -n${BUF_NUM} -H -M ${JACK_ALSA_OPTS} -s --rate ${RATE} &
# jack_bufsize $BUF_SIZE
JACKD_PID=`pidof jackd`
sudo chrt --fifo -p ${JACKD_PRIO} ${JACKD_PID}


# START CHUCK

sleep 1
(
    sleep 1 ;
    CHUCK_PID=`pidof chuck` ;
sudo renice -20 ${CHUCK_PID} ;
    echo "niced chuck, pid ", `pidof chuck` ;
    sudo chrt --fifo -p ${CHUCK_PRIO}  ${CHUCK_PID} ;
) &

CHUCK_OPTS=" --in1 --srate:${RATE}  --bufnum:${BUF_NUM} --adaptive:${BUF_SIZE}"
~/chuck ${CHUCK_OPTS} Looper/looper-pedal.ck

killall jackd


