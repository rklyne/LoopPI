#! /bin/bash

TOP_PRIO=${1:-70}
TOP_TOP_PRIO=${1:-90}
echo $0, $1
echo "Setting IRQ handlers to FIFO priority ${PRIO}"

TOP_TOP_KEYWORDS="DMA VCHIQ"
TOP_KEYWORDS="ksoftirq dwc_otg DWC"
# EXPERIMENTAL
MID_KEYWORDS="${KEYWORDS} mmc"
MID_PRIO=20

set_them_all() {
    KEYWORDS=$1
    PRIO=$2
    echo "Setting pri $PRIO for $KEYWORDS"
    PIDS=" "
    for kwd in $KEYWORDS; do
        PIDS="${PIDS} `ps aux | grep "${kwd}" | grep -v grep | awk '{print $2}'`"
    done
    echo $PIDS

    for pid in $PIDS;
        do sudo  chrt --fifo -p ${PRIO} ${pid} ;
    done

    echo "Reading back IRQ priorities"
    for pid in $PIDS;
        do sudo  chrt --fifo -p ${pid} ;
    done
};

set_them_all "$TOP_TOP_KEYWORDS" "$TOP_TOP_PRIO" 
set_them_all "$TOP_KEYWORDS" "$TOP_PRIO" 
set_them_all "$MID_KEYWORDS" "$MID_PRIO" 


