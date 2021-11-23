#!/bin/bash

cd `dirname $0`
curdir=`pwd`

if [[ ! $1 || ! $@ == *'.profile'* ]]; then
  echo 'Missed params!'
  echo 'Type this and run:'
  echo "sudo $0 \$USER && source ~/.profile"
  exit
fi
curuser=$1

SRV_NAME='rmtbutton'

if [[ "$EUID" -ne 0 ]]
  then echo "Please run as root"
  exit
fi

# Set permission
chmod +x *.sh

# Set environment
if [[ -z `grep 'USB_BUTTON_HOME' /home/$curuser/.profile` ]] ; then
    export USB_BUTTON_HOME="$curdir";
    echo '' >> /home/$curuser/.profile;
    echo '# USB Button path' >> /home/$curuser/.profile;
    echo "export USB_BUTTON_HOME='$curdir'" >> /home/$curuser/.profile;
    echo "Env Variable USB_BUTTON_HOME created";
fi

# Copy to system folder
cp $SRV_NAME.service /etc/systemd/system/$SRV_NAME.service

# Register service and run
if [[ `systemctl is-enabled $SRV_NAME` == 'enabled' ]]; then
  systemctl enable $SRV_NAME
  echo "Service $SRV_NAME enabled"
fi
if [[ `systemctl is-active $SRV_NAME` == 'active' ]]; then
  systemctl stop $SRV_NAME
  echo "Service $SRV_NAME stopped"
fi
systemctl daemon-reload
systemctl start $SRV_NAME
systemctl status $SRV_NAME
