#!/bin/bash

./prepare_system.sh

# JACKD / CHUCK config vars
JACKD_PRIO=58
CHUCK_PRIO=56
CHUCK_CMD=~pi/chuck
JACK_CMD=jackd
CHUCK_PROGRAM=Looper/looper-pedal-unlimited.ck
if [[ $1 == "playthrough" ]]; then
    CHUCK_PROGRAM=Experiments/playthrough.ck;
fi
if [[ $1 == "sin" ]]; then
    CHUCK_PROGRAM=Experiments/sin.ck;
fi
# CHUCK_PROGRAM=Experiments/sin.ck
# RATE=44100
RATE=48000
BUF_SIZE=$((48 * 2))
BUF_NUM=3
JACK_OPTS=" -R -P${JACKD_PRIO} -p64 -cc "
JACK_OPTS="${JACK_OPTS} "
JACK_ALSA_OPTS="-s -S -z none -D "
# Mono in:
JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -i1 -o2 "
# named sound card
IN_DEV=0
OUT_DEV=1
JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -Phw:${OUT_DEV} -Chw:${IN_DEV} "

# Overrides for debugging
# BUF_SIZE=96
# BUF_NUM=3

# EXTRA_INPUT_LATENCY=$((2 * ${BUF_SIZE}))
# JACK_ALSA_OPTS="${JACK_ALSA_OPTS} -I${EXTRA_INPUT_LATENCY} "

# Jackd free mode
# JACK_CMD="echo jackd"
# CHUCK_CMD=~pi/chuck.alsa


# START JACKD

RUN_FAST="chrt --fifo ${JACKD_PRIO}"
# export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
JACK_CMD_LINE="$RUN_FAST ${JACK_CMD}  --realtime -t10000 ${JACK_OPTS} -d alsa -p${BUF_SIZE} -n${BUF_NUM} ${JACK_ALSA_OPTS} -s --rate ${RATE}"
echo $JACK_CMD_LINE
$JACK_CMD_LINE &
JACKD_PID=`pidof jackd`
# sudo chrt --fifo -p ${JACKD_PRIO} ${JACKD_PID}


# START CHUCK

sleep 1
(
    sleep 1 ;
    CHUCK_PID=`pidof chuck` ;
    # sudo renice -20 ${CHUCK_PID} ;
    # echo "niced chuck, pid ", `pidof chuck` ;
    # sudo chrt --fifo -p ${CHUCK_PRIO}  ${CHUCK_PID} ;
    # sudo chrt --fifo -p ${JACKD_PRIO} ${JACKD_PID};
) &

jack_bufsize $BUF_SIZE

CHUCK_OPTS=" --in1 --srate:${RATE}  --bufnum:${BUF_NUM} "
# CHUCK_OPTS="${CHUCK_OPTS} --adaptive:${BUF_SIZE}"

# Run main process
CHUCK_EXEC="${RUN_FAST} ${CHUCK_CMD} ${CHUCK_OPTS} ${CHUCK_PROGRAM}"
echo "Chuck exec - ${CHUCK_EXEC}"
$CHUCK_EXEC


# Clean up when main process exits
killall jackd

