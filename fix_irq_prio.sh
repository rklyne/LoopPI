#! /bin/bash

PRIO=50

for pid in `ps aux | grep irq | grep ksoft | awk '{print $2}'`;
    do sudo  chrt --fifo -p ${PRIO} ${pid} ;
done
for pid in `ps aux | grep irq | grep ksoft | awk '{print $2}'`;
    do sudo  chrt --fifo -p ${pid} ;
done


