# set to true (shred on), false (shred off)
export ARMED=false

# LED pins
# every USB port matches to one set of LED

#GND_00=Pin-39
export RED_00=26
export GREEN_00=19

#GND_01=Pin-34
export RED_01=16
export GREEN_01=20

#GND_02=Pin-25
export RED_02=11
export GREEN_02=9

#GND_03=Pin-9
export RED_03=4
export GREEN_03=3

# Assign names to states
export ON="1"
export OFF="0"


export LOG=/var/log/flush.log
export BASE_GPIO_PATH=/sys/class/gpio


export SERVICE=flush-sd
export SERVICE_FILE=/lib/systemd/system/${SERVICE}\@.service
export WRAP=wrap.sh
export FLUSH=flush.sh
export RULE=99-flush-sd.rules