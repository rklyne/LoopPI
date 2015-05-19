#!/bin/bash

##   git clone https://github.com/rklyne/LoopPI.git
##   cd LoopPI
##   ./install-script.sh

sudo apt-get update
sudo apt-get install -y zsh vim exuberant-ctags chuck make python-pip cython python-dev liblo-dev jackd python2.6-dev python2.7-dev bison python-dev flex htop libjack-jackd2-dev libsndfile-dev libasound2-dev

mkdir ~/build
(
    cd ~/build ;
    wget http://das.nasophon.de/download/pyliblo-0.9.2.tar.gz ;
    tar -pvzxf *.tar.gz ;
    cd pyliblo* ;
    python setup.py install ;
)

(
    cd `dirname $0`;
    ./prepare-runtime.sh;
)

# JACK repo
# redundant - in core raspbian now
# (
#     sudo wget -O - http://rpi.autostatic.com/autostatic.gpg.key | sudo apt-key add -
#     sudo wget -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list
#     sudo apt-get update
# )


# ADD CHUCK BUILD
(
    cd ~/build;
    wget http://chuck.cs.princeton.edu/release/files/chuck-1.3.5.1.tgz ;
    tar -pvzxf chuck-1.3.5.1.tgz ;
    cd chuck-1.3.5.1/src ;
    make -j 6 linux-jack ;
    cp ./chuck ~/chuck ;
)


#### configure dbus

sudo sed -i "s|</busconfig>|<policy user=\"pi\"><allow own=\"org.freedesktop.ReserveDevice1.Audio1\"/></policy></busconfig>|" /etc/dbus-1/system.conf
sudo service dbus restart



