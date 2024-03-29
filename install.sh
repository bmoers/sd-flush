#! /bin/sh

if [ $(id -u) -ne 0 ]
then echo "Please run as root"
    exit
fi

DIR=$(cd `dirname $0` && pwd)
. $DIR/env.sh

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

cat > /etc/systemd/system/flush-startup.service << EOF
[Unit]
Description=SD Flush init
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=base.target

[Service]
Type=oneshot
ExecStart=${DIR}/init.sh

[Install]
WantedBy=base.target
EOF

systemctl enable /etc/systemd/system/flush-startup.service

echo "change permission on init script $DIR/init.sh"
chmod +x $DIR/init.sh

echo "change permission on flush script $DIR/$FLUSH"
chmod +x $DIR/$FLUSH

echo "init log file ${LOG}"
touch $LOG
chmod +x /etc/udev/rules.d/$RULE

echo "run init.sh"
$DIR/init.sh

echo "configure service ${SERVICE_FILE}"
cat > ${SERVICE_FILE} << EOF
[Unit]
Description=flush sd card

[Service]
Type=oneshot
TimeoutStartSec=300
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
if [ -n "$RULE" ] ; then
    echo "removing existing rule /etc/udev/rules.d/$RULE"
    rm -rf /etc/udev/rules.d/$RULE
fi

# create rule
echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", RUN+=\"$DIR/$WRAP \$env{DEVNAME}\"" >> /etc/udev/rules.d/$RULE
chmod 755 /etc/udev/rules.d/$RULE

#echo "#ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}==\"${SERVICE}@%E{DEVNAME}.service\"" >> /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

echo "#ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", PROGRAM=\"/bin/systemd-escape -p --template=${SERVICE}@.service \$env{DEVNAME}.\$env{SEQNUM}\", ENV{SYSTEMD_WANTS}+=\"%c\"" >> /etc/udev/rules.d/$RULE
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