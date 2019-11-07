#! /bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

LOG=/var/log/flush.log

#env >>$LOG
#file "/sys${DEVPATH}" >>$LOG


BASE_GPIO_PATH=/sys/class/gpio

# Assign names to GPIO pin numbers for each light

#GND_01=Pin-39
RED_01=26
GREEN_01=19

#GND_02=Pin-34
RED_02=16
GREEN_02=20

#GND_03=Pin-25
RED_03=11
GREEN_03=9

#GND_04=Pin-9
RED_04=4
GREEN_04=3

# Assign names to states
ON="1"
OFF="0"

# Utility function to export a pin if not already exported
exportPin(){
  if [ ! -e $BASE_GPIO_PATH/gpio$1 ]; then
    echo "$1" > $BASE_GPIO_PATH/export
  fi
}

# Utility function to set a pin as an output
setOutput(){
  echo "out" > $BASE_GPIO_PATH/gpio$1/direction
}

# Utility function to change state of a light
setLightState(){
  echo $2 > $BASE_GPIO_PATH/gpio$1/value
}

for i in {1..4}
do
  R="RED_0$i"
  G="GREEN_0$i"
  
  # Export pins so that we can use them

  echo "exportPin ${!R}" >> $LOG
  echo "exportPin ${!G}" >> $LOG

  echo "setOutput ${!R}" >> $LOG
  echo "setOutput ${!G}" >> $LOG

  exportPin ${!R}
  exportPin ${!G}

  # Set pins as outputs
  setOutput ${!R}
  setOutput ${!G}
 
done

# setLight RED 1 ON
setLight(){
  R="$1_0$2"
  echo "setLightState ${!R} $3" >> $LOG
  setLightState ${!R} $3
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
    echo "shred -f -n 1 ${DISC} ...."
    #time ( shred -f -n 1 ${DISC} ) 2>&1 1>/dev/null >> $LOG
    time (sleep 5) 2>&1 1>/dev/null >> $LOG
    echo "done" >> $LOG

    setLight "RED" $DEVICE_NR $OFF
    setLight "GREEN" $DEVICE_NR $ON
    
}


if [ "${ACTION}" = change -a -d "/sys${DEVPATH}" ]; then

    # ID_INSTANCE=0:2
    #${ID_INSTANCE}

    DEVICE_NR="$(cut -d':' -f2 <<<"$ID_INSTANCE")"

    DISC_EXISTS=false
    PARTITION_EXISTS=false

    echo "DEVNAME          : ${DEVNAME} " >> $LOG

    if $(/sbin/sfdisk -l ${DEVNAME} &> /dev/null) ;
    then
        echo "DISC removed" >> $LOG
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $OFF
        exit 0
    else 
        DISC_EXISTS=true
    fi
    echo "DISC_EXISTS      : ${DISC_EXISTS} " >> $LOG
    

    if $(/sbin/sfdisk -d ${DEVNAME} &> /dev/null) ;
    then
        echo "DISC has no partition, seems to be clean" >> $LOG
        echo "PARTITION_EXISTS > $PARTITION_EXISTS" >> $LOG
      
        setLight "RED" $DEVICE_NR $OFF
        setLight "GREEN" $DEVICE_NR $ON
        exit 0
    else    
        PARTITION_EXISTS=true
    fi
    echo "PARTITION_EXISTS : ${PARTITION_EXISTS} " >> $LOG

    #DISC_NAME=`lsblk -no pkname ${DEVNAME} | sed -r '/^\s*$/d'`
    #if [ -z "$DISC_NAME" ];
    #then
    #    echo "DISC name is empty, seems to be clean" >> $LOG
    #    echo "DISC_NAME > $DISC_NAME" >> $LOG
    #    setLightState $RED $OFF
    #    setLightState $GREEN $ON
    #    exit 1
    #fi

    
    echo "DISC_NAME        : ${DEVNAME} " >> $LOG
  
    echo "DISC to be flushed ${DEVNAME}" >> $LOG

    echo "FLUSH DRIVE ---------------------------------- ${ENV}" >> $LOG
    flush_drive ${DEVNAME} ${DEVICE_NR}
else   
    echo "Nothing to to        : ${ENV} " >> $LOG
fi
