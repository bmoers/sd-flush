#GND_01=Pin-39
export RED_01=26
export GREEN_01=19

#GND_02=Pin-34
export RED_02=16
export GREEN_02=20

#GND_03=Pin-25
export RED_03=11
export GREEN_03=9

#GND_04=Pin-9
export RED_04=4
export GREEN_04=3

# Assign names to states
export ON="1"
export OFF="0"


export LOG=/var/log/flush.log
export BASE_GPIO_PATH=/sys/class/gpio


export SERVICE=flush-sd
export SERVICE_FILE=/lib/systemd/system/${SERVICE}\@.service
export FLUSH=flush.sh
export RULE=99-flush-sd.rules