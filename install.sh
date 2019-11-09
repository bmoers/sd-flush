#! /bin/bash

#  http://blog.fraggod.net/2012/06/16/proper-ish-way-to-start-long-running-systemd-service-on-udev-event-device-hotplug.html
#  http://blog.fraggod.net/2015/01/12/starting-systemd-service-instance-for-device-from-udev.html

# IGNORE https://stackoverflow.com/questions/49349712/udev-detach-script-to-wait-for-mounting
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
source $DIR/env.sh


echo "install pigs" >> $LOG
apt-get install pigpio
systemctl start pigpiod
systemctl enable pigpiod

# fix to listen to ip4 instead of ip6
cat > /lib/systemd/system/pigpiod.service << EOF
[Unit]
Description=Daemon required to control GPIO pins via pigpio
[Service]
ExecStart=/usr/bin/pigpiod -l -n 127.0.0.1
ExecStop=/bin/systemctl kill pigpiod
Type=forking
[Install]
WantedBy=multi-user.target
EOF

# apply changes
systemctl daemon-reload


echo "change permission on flush script $DIR/$FLUSH"
chmod chmod +x $DIR/$FLUSH

echo "init log file ${LOG}"
touch $LOG
chmod chmod +x /etc/udev/rules.d/$RULE

# init pins and blink
initPin(){
    pigs modes $1 w
    # blink
    pigs w $1 $ON mils 1000 w $1 $OFF &
}

echo "init LED"
for i in {1..4}
do
    R="RED_0$i"
    G="GREEN_0$i"
    initPin ${!R}
    initPin ${!G}
done


echo "configure service ${SERVICE_FILE}"

cat > ${SERVICE_FILE} << EOF
[Unit]
Description=flush sd card

[Service]
Type=oneshot
TimeoutStartSec=30
ExecStart=$DIR/$FLUSH /%I
EOF

#cat > ${SERVICE_FILE} << EOF
#[Unit]
#Description=changes to dvd drive
#
#[Service]
#Type=oneshot
#ExecStart=$DIR/$FLUSH %I
#
#[Install]
#WantedBy=multi-user.target
#EOF

echo "reload service daemon"

#systemctl enable ${SERVICE_FILE}
systemctl daemon-reload


echo "configure udev rule /etc/udev/rules.d/$RULE"

# remove in case script is executed multiple times
rm -rf /etc/udev/rules.d/$RULE

# create rule
#echo "#ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", RUN+=\"$DIR/$FLUSH\"" >> /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

#echo "#ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}==\"${SERVICE}@%E{DEVNAME}.service\"" >> /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", PROGRAM=\"/bin/systemd-escape -p --template=${SERVICE}@.service \$env{DEVNAME}.\$env{SEQNUM}\", ENV{SYSTEMD_WANTS}+=\"%c\"" >> /etc/udev/rules.d/$RULE
chmod 755 /etc/udev/rules.d/$RULE

#>> /lib/systemd/system/flush-sd@.service
# /lib/systemd/system/flush-sd@.service

#----> funktioniert !!
#ACTION=="change", KERNEL=="sd?", ENV{ID_BUS}=="usb", ENV{DISK_MEDIA_CHANGE}=="1", ENV{DEVTYPE}=="disk", ENV{SYSTEMD_WANTS}+="flush-sd@dev-%k.service"
#ACTION=="change", KERNEL=="sd?", ENV{ID_BUS}=="usb", ENV{DISK_MEDIA_CHANGE}=="1", ENV{DEVTYPE}=="disk", PROGRAM="/bin/systemd-escape -p --template=flush-sd@.service $env{DEVNAME}", ENV{SYSTEMD_WANTS}+="%c"
#ACTION=="change", KERNEL=="sd?", ENV{ID_BUS}=="usb", ENV{DISK_MEDIA_CHANGE}=="1", ENV{DEVTYPE}=="disk", PROGRAM="/bin/systemd-escape -p --template=flush-sd@.service $env{DEVNAME}.$env{SEQNUM}", ENV{SYSTEMD_WANTS}+="%c"
#ACTION=="change", KERNEL=="sd?", ENV{ID_BUS}=="usb", ENV{DISK_MEDIA_CHANGE}=="1", ENV{DEVTYPE}=="disk", PROGRAM="/bin/systemd-escape -p --template=${SERVICE}@.service \$env{DEVNAME}.\$env{SEQNUM}", ENV{SYSTEMD_WANTS}+="%c"

# systemctl stop [servicename]
# systemctl disable [servicename]
# rm /etc/systemd/system/[servicename]
# rm /etc/systemd/system/[servicename] symlinks that might be related
# systemctl daemon-reload
# systemctl reset-failed

# tail -300f /var/log/flush.log
# journalctl -f&
# udevadm monitor --environment
# udevadm monitor -p systemd
# sudo systemctl show flush-sd@dev-sdc.service
# sudo systemctl start flush-sd@dev-sdc.service
# sudo systemctl status flush-sd@dev-sdc.service
# systemd-escape -p --template=flush-sd@.service /dev/sdc 23424

# systemctl --type=service
# systemctl status drive-change.service
# systemctl enable /etc/systemd/system/drive-change\@.service

echo "refreshing the rules"
# refresh rules
udevadm control --reload-rules && udevadm trigger

echo "plug the sd devices out and back in now"

exit 0

