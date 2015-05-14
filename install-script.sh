#!/bin/bash

##   git clone https://github.com/rklyne/LoopPI.git
##   cd LoopPI
##   ./install-script.sh


apt-get install -y zsh vim exuberant-ctags chuck make python-pip cython python-dev liblo-dev jackd python2.6-dev python2.7-dev
(
wget http://das.nasophon.de/download/pyliblo-0.9.2.tar.gz ;
tar -pvzxf *.tar.gz ;
cd pyliblo*;
python setup.py install
)

(
    cd `dirname $0`;
    ./prepare-runtime.sh;
)

# # JACK repo
# wget -O - http://rpi.autostatic.com/autostatic.gpg.key | sudo apt-key add -
# sudo wget -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list
# sudo apt-get update

# ADD CHUCK BUILD
wget http://chuck.cs.princeton.edu/release/files/chuck-1.3.5.1.tgz
tar -pvzxf chuck-1.3.5.1.tgz
(
    cd chuck-1.3.5.1/src;
    make linux-jack
    make install
)


