#!/bin/bash

# Some system prep
sudo service ntp stop
sudo service triggerhappy stop
sudo service cron stop
sudo service dphys-swapfile stop
sudo mount -o remount,size=128M /dev/shm
for CPU in 0 1 2 3; do
    echo -n "performance" | sudo tee /sys/devices/system/cpu/cpu${CPU}/cpufreq/scaling_governor ;
done
# ./fix_irq_prio.sh 98

