#! /bin/bash

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/env.sh

#echo "param 1 : ${1}" >> $LOG

# load vars from udev for current drive
DEVNAME="$(cut -d'.' -f1 <<<"$1")"
eval $(udevadm info --query=env --export $DEVNAME)
#env >> $LOG

date +%F-%T >> $LOG

# setLight RED 1 ON
setLight(){
    R="$1_0$2"
    echo "LED - Color: $1, DeviceID: $2, State: $3, Pin: ${!R} " >> $LOG
    pigs modes ${!R} w
    pigs w ${!R} $3
}

flush_drive () {
    
    DISC=$1
    DEVICE_NR=$2
    
    setLight "RED" $DEVICE_NR $ON
    setLight "GREEN" $DEVICE_NR $OFF
    
    echo "*** cleaning DISC ${DISC} ***" >> $LOG
    
    
    echo "unmount ${DISC}?" >> $LOG
    #unmount ${DISC}?
    
    echo "shredding " >> $LOG
    #
    #shred -f -z -n 1 ${DISC} | col -b -l 10 >> $LOG
    echo "shred -f -n 1 ${DISC} .... (will take some time) " >> $LOG
    #time ( shred -f -n 1 ${DISC} ) 2>&1 1>/dev/null >> $LOG
    time (sleep 30) 2>&1 1>/dev/null >> $LOG
    echo "done" >> $LOG
    
    setLight "RED" $DEVICE_NR $OFF
    setLight "GREEN" $DEVICE_NR $ON
}


if [ -d "/sys${DEVPATH}" ]; then
    
    # ID_INSTANCE=0:2
    #${ID_INSTANCE}
    
    DEVICE_NR="$(cut -d':' -f2 <<<"$ID_INSTANCE")"
    
    DISC_EXISTS=false
    PARTITION_EXISTS=false
    
    echo "DEVNAME          : ${DEVNAME} " >> $LOG
    
    if $(/sbin/sfdisk -l ${DEVNAME} &> /dev/null) ;
    then
        DISC_EXISTS=true
    else
        echo "DISC removed" >> $LOG
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $OFF
        exit 0
    fi
    echo "DISC_EXISTS      : ${DISC_EXISTS} " >> $LOG
    
    
    if $(/sbin/sfdisk -d ${DEVNAME} &> /dev/null) ;
    then
        PARTITION_EXISTS=true
    else
        echo "DISC has no partition, seems to be clean" >> $LOG
        echo "PARTITION_EXISTS > $PARTITION_EXISTS" >> $LOG
        
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $ON
        exit 0
    fi
    echo "PARTITION_EXISTS : ${PARTITION_EXISTS} " >> $LOG
    
    
    
    
    echo "DISC_NAME        : ${DEVNAME} " >> $LOG
    
    echo "DISC to be flushed ${DEVNAME}" >> $LOG
    
    echo "FLUSH DRIVE ---------------------------------- ${ENV}" >> $LOG
    flush_drive ${DEVNAME} ${DEVICE_NR}
else
    echo "Nothing to do        : ${ENV} " >> $LOG
fi
