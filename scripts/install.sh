#!/bin/bash

SRV_NAME='rmtbutton'

cd `dirname $0`
curdir=`pwd`

if [[ $1 == '--help' ]]; then
  echo 'Type this and run:'
  echo "$0 && source ~/.profile"
  exit
fi

# if [[ "$EUID" -ne 0 ]]
#   then echo "Please run as root"
#   exit
# fi

# Set permission
chmod +x *.sh

# Set environment
if [[ -z `grep 'USB_BUTTON_HOME' ~/.profile` ]] ; then
  echo '' >> ~/.profile
  echo '# USB Button path' >> ~/.profile
  echo "export USB_BUTTON_HOME='$curdir'" >> ~/.profile
  echo "USB_BUTTON_HOME added to .profile"
fi

if [[ $USB_BUTTON_HOME ]]; then
  unset USB_BUTTON_HOME
fi

if [[ ! $USB_BUTTON_HOME ]]; then
  export USB_BUTTON_HOME="$curdir"
  systemctl --user import-environment USB_BUTTON_HOME
  echo "USB_BUTTON_HOME added to current session"
fi

# Copy to system folder
mkdir -p ~/.config/systemd/user/
cp $SRV_NAME.service ~/.config/systemd/user/$SRV_NAME.service

# Register service and run
if [[ `systemctl --user is-enabled $SRV_NAME` == 'disabled' ]]; then
  systemctl --user enable $SRV_NAME
  echo "Service $SRV_NAME enabled"
fi
if [[ `systemctl --user is-active $SRV_NAME` == 'active' ]]; then
  systemctl --user stop $SRV_NAME
  echo "Service $SRV_NAME stopped"
fi
systemctl --user daemon-reload
systemctl --user start $SRV_NAME
systemctl --user status $SRV_NAME
