#!/bin/bash
apt-get install -y zsh vim exuberant-ctags chuck make python-pip cython python-dev liblo-dev jackd python2.6-dev python2.7-dev
(
wget http://das.nasophon.de/download/pyliblo-0.9.2.tar.gz ;
tar -pvzxf *.tar.gz ;
cd pyliblo*;
python setup.py install
)

# pip install pyliblo
git clone https://github.com/rklyne/LoopPI.git
cd LoopPI

