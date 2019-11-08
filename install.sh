#! /bin/bash

#  http://blog.fraggod.net/2012/06/16/proper-ish-way-to-start-long-running-systemd-service-on-udev-event-device-hotplug.html
#  http://blog.fraggod.net/2015/01/12/starting-systemd-service-instance-for-device-from-udev.html

# https://stackoverflow.com/questions/49349712/udev-detach-script-to-wait-for-mounting
# https://forums.opensuse.org/showthread.php/485261-Script-run-from-udev-rule-gets-killed-shortly-after-start

# https://www.pcsuggest.com/run-shell-scripts-from-udev-rules/  

# --> https://wiki.archlinux.de/title/Udev#Ausf.C3.BChren_bei_anstecken_von_USB_Ger.C3.A4ten

# ---> https://superuser.com/questions/924683/passing-udev-environment-variables-to-systemd-service-execution
# ---> http://0pointer.de/blog/projects/instances.html
#      https://codingequanimity.tumblr.com/post/129163035064/passing-variables-from-udev-to-systemd/amp


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SERVICE=drive-change
FLUSH=flush.sh
RULE=99-flush-sd.rules
LOG=/var/log/flush.log

echo "change permission on flush script $DIR/$FLUSH"
chmod chmod +x $DIR/$FLUSH

echo "init log file ${LOG}"
touch $LOG
chmod chmod +x /etc/udev/rules.d/$RULE

echo "configure udev rule /etc/udev/rules.d/$RULE"

# remove in case script is executed multiple times
rm -rf /etc/udev/rules.d/$RULE

# create rule
#echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", RUN+=\"$DIR/$FLUSH\"" > /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

#####echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", PROGRAM=\"/usr/bin/systemd-escape -p --template=flush-sd@.service $env{DEVNAME}\", ENV{SYSTEMD_WANTS}+=\"%c\"" > /etc/udev/rules.d/$RULE 

echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}==\"${SERVICE}@%E{DEVNAME}.service\"" > /etc/udev/rules.d/$RULE
chmod 755 /etc/udev/rules.d/$RULE


#>> /lib/systemd/system/flush-sd@.service
#/etc/systemd/system/flush-sd@.service

echo "configure service /etc/systemd/system/${SERVICE}\@.service"

cat > /etc/systemd/system/${SERVICE}\@.service << EOF
[Unit]
Description=Flush SD Drive

[Service]
Type=oneshot
ExecStart=$DIR/$FLUSH %I

[Install]
WantedBy=multi-user.target
EOF

echo "reload service daemon"
systemctl daemon-reload


echo "refreshing the rules"
# refresh rules
udevadm control --reload-rules
udevadm trigger

echo "plug the sd devices out and back in now"

exit 0

