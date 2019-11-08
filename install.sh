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

source ./env.sh

#sudo apt-get install at --fix-missing -y

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


echo "change permission on flush script $DIR/$FLUSH"
chmod chmod +x $DIR/$FLUSH

echo "init log file ${LOG}"
touch $LOG
chmod chmod +x /etc/udev/rules.d/$RULE

# Utility function to set a pin as an output
setOutput(){
  echo "out" > $BASE_GPIO_PATH/gpio$1/direction
}

# Utility function to export a pin if not already exported
initPin(){
  if [ ! -e $BASE_GPIO_PATH/gpio$1 ]; then
    echo "$1" > $BASE_GPIO_PATH/export
  fi
  setOutput $1

  echo $ON > $BASE_GPIO_PATH/gpio$1/value
  sleep 0.2
  echo $OFF > $BASE_GPIO_PATH/gpio$1/value
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
BindTo=%i.device
After=%i.device

[Service]
Type=oneshot
TimeoutStartSec=300
ExecStart=$DIR/$FLUSH /%I
EOF

echo "reload service daemon"

#systemctl enable ${SERVICE_FILE}
systemctl daemon-reload


echo "configure udev rule /etc/udev/rules.d/$RULE"

# remove in case script is executed multiple times
rm -rf /etc/udev/rules.d/$RULE

# create rule
#echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", RUN+=\"$DIR/$FLUSH\"" > /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

#echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}==\"${SERVICE}@%E{DEVNAME}.service\"" > /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

#echo "ACTION==\"change\", KERNEL==\"sd?\", ENV{ID_BUS}==\"usb\", ENV{DISK_MEDIA_CHANGE}==\"1\", ENV{DEVTYPE}==\"disk\", PROGRAM=\"systemd-escape -p --template=${SERVICE}@.service $env{DEVNAME}\", ENV{SYSTEMD_WANTS}+=\"%c\"" > /etc/udev/rules.d/$RULE
#chmod 755 /etc/udev/rules.d/$RULE

cat > /etc/udev/rules.d/$RULE << EOF
ACTION=="change", KERNEL=="sd?", ENV{ID_BUS}=="usb", ENV{DISK_MEDIA_CHANGE}=="1", ENV{DEVTYPE}=="disk", \
  PROGRAM="systemd-escape -p --template=${SERVICE}@.service $env{DEVNAME}",\
  ENV{SYSTEMD_WANTS}+="%c"
EOF
chmod 755 /etc/udev/rules.d/$RULE

#>> /lib/systemd/system/flush-sd@.service
#/etc/systemd/system/flush-sd@.service


# systemctl stop [servicename]
# systemctl disable [servicename]
# rm /etc/systemd/system/[servicename]
# rm /etc/systemd/system/[servicename] symlinks that might be related
# systemctl daemon-reload
# systemctl reset-failed

# systemctl --type=service
# systemctl status drive-change.service
# systemctl enable /etc/systemd/system/drive-change\@.service

echo "refreshing the rules"
# refresh rules
udevadm control --reload-rules && udevadm trigger

echo "plug the sd devices out and back in now"

exit 0

