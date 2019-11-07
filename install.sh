#! /bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLUSH=flush.sh
RULE=99-flush-sd.rules
LOG=/var/log/flush.log

echo "change permission on flush script $DIR/$FLUSH"
chmod 755 $DIR/$FLUSH

echo "init log file ${LOG}"
touch $LOG
chmod 755 /etc/udev/rules.d/$RULE

echo "configure udev rule /etc/udev/rules.d/$RULE"

# remove in case script is executed multiple times
rm -rf /etc/udev/rules.d/$RULE

# create rule
echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", RUN+=\"$DIR/$FLUSH\"" > /etc/udev/rules.d/$RULE
chmod 755 /etc/udev/rules.d/$RULE

echo "refreshing the rules"
# refresh rules
udevadm control --reload-rules
udevadm trigger

echo "plug the sd devices out and back in now"

exit 0

