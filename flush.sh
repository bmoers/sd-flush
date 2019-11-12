#! /bin/sh

if [ $(id -u) -ne 0 ]
then echo "Please run as root"
    exit
fi

DIR=$(cd `dirname $0` && pwd)
. $DIR/env.sh

# load vars from udev for current drive
DEVNAME="$(echo $1 | cut -d'.' -f1 )"
eval $(udevadm info --query=env --export $DEVNAME)

DEVICE_NR="$(echo $DEVPATH | sed -r 's/.*\/host([0-9]+)\/.*/\1/')"
if [ -e ${DIR}/lock_${DEVICE_NR} ]; then
    echo "there is already a running job for $DEVNAME" >> $LOG
    exit 1
else
    touch ${DIR}/lock_${DEVICE_NR}
fi

#env >> $LOG

date +%F-%T >> $LOG

# setLight RED 1 ON
setLight(){
    eval "PIN=\$$1_0$2"
    echo "LED - Color: $1, DeviceID: $2, State: $3, Pin: $PIN " >> $LOG
    pigs modes $PIN w
    pigs w $PIN $3
}

flush_drive () {
    
    DISC=$1
    DEVICE_NR=$2
    
    setLight "RED" $DEVICE_NR $ON
    setLight "GREEN" $DEVICE_NR $OFF
    
    echo "********* cleaning DISC ${DISC} *********" >> $LOG
    
    echo "unmount ${DISC}?" >> $LOG
    unmount ${DISC}?
    
    echo "shredding start at `date +%F-%T`" >> $LOG
    
    if [ $ARMED = "true" ]; then
        echo "shred -f -n 1 ${DISC} .... (will take some time) " >> $LOG
        shred -f -v -n 1 ${DISC} 2>&1 | tee -a $LOG
    else
        echo "simulate shred " >> $LOG
        sleep 3 2>> $LOG
    fi;
    
    echo "shredding completed at `date +%F-%T`" >> $LOG
    
    setLight "RED" $DEVICE_NR $OFF
    setLight "GREEN" $DEVICE_NR $ON
}

cleanup (){
    # clean the lock file
    rm -rf ${DIR}/lock_${DEVICE_NR}
}

if [ -d "/sys${DEVPATH}" ]; then
    
    # ID_INSTANCE=0:2
    #${ID_INSTANCE}
    
    #DEVICE_NR="$(echo $ID_INSTANCE | cut -d':' -f2)"
    
    DISC_EXISTS=false
    PARTITION_EXISTS=false
    
    echo "DEVNAME          : ${DEVNAME} " >> $LOG
    echo "DEVICE_NR        : ${DEVICE_NR} " >> $LOG
    
    /sbin/sfdisk -l ${DEVNAME} > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        DISC_EXISTS=true
    else
        echo "DISC removed" >> $LOG
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $OFF
        cleanup
        exit 0
    fi
    echo "DISC_EXISTS      : ${DISC_EXISTS} " >> $LOG
    
    /sbin/sfdisk -d ${DEVNAME} > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        PARTITION_EXISTS=true
    else
        echo "DISC has no partition, seems to be clean" >> $LOG
        echo "PARTITION_EXISTS > $PARTITION_EXISTS" >> $LOG
        
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $ON
        cleanup
        exit 0
    fi
    echo "PARTITION_EXISTS : ${PARTITION_EXISTS} " >> $LOG
    echo "DISC_NAME        : ${DEVNAME} " >> $LOG
    echo "DISC to be flushed ${DEVNAME}" >> $LOG
    
    flush_drive ${DEVNAME} ${DEVICE_NR}
else
    echo "Nothing to do        : ${ENV} " >> $LOG
fi

cleanup
exit 0
