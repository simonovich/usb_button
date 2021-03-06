#!/bin/bash

# Comminication between USB-buttons
#
# If problem with USB port, run this:
# stty sane <your_serial_port>
#
cd `dirname $0`
curdir=`pwd`

# This adds traps for SIGINT and SIGTERM and causes the exit command to run if our script receives those signals,
# which in turn will trigger the EXIT trap and run kill 0,
# which will kill the current script and all the background processes.
# The ERR trap is optional. It is effectively equivalent to set -e and will cause our script to exit on error.
#
#trap "exit" INT TERM ERR
trap "kill 0" EXIT

#
# Load MQTT and Device settings
#
source settings.sh
if [[ $? == 1 ]]; then
  echo 'Please, create Settings.sh and write the parameters into it:'
  echo ''
  echo "MQTT_SERVER='your_mqtt_broker' # mqtt.by"
  echo "MQTT_PORT=your_mqtt_port # 1883, 1884, 1885, 1886, 1887, 1888, 1889"
  echo "MQTT_USER='your_mqtt_login' # user login"
  echo "MQTT_PASS='your_mqtt_password' # user password"
  echo "MQTT_LOC_CLIENT_ID='your_local_id' # local client id"
  echo "MQTT_RMT_CLIENT_ID='your_remote_id' # remote client id"
  echo "MQTT_LOC_TOPIC='local_topic_name' # topic for your device"
  echo "MQTT_RMT_TOPIC='remote_topic_name' # topic for remote device"
  echo "MQTT_LOG='path_to_log_file' # log for incoming MQTT messages"
  echo ''
  echo "USB_PORT='your_port' # Serial port (by sample /dev/ttyUSB0 or /dev/ttyACM0)"
  echo ''
  exit;
fi

NUMOFLINES=0
if [[ -e $MQTT_LOG ]]; then
  NUMOFLINES=$(wc -l < $MQTT_LOG)
fi

# Subscribe
mosquitto_sub -h $MQTT_SERVER -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PASS -I $MQTT_LOC_CLIENT_ID -v -d -t $MQTT_LOC_TOPIC >> $MQTT_LOG &
echo 'MQTT subscription activated'

# USB Serial listing...
echo "Connect to $USB_PORT..."
until [[ -e "$USB_PORT" ]]; do
  sleep 1;
done

# Set settings for USB Serial port
stty -F $USB_PORT -opost -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke

exec 99<>$USB_PORT #(or /dev/ttyUSB0...etc)
echo "Serial port" $USB_PORT " is opened"
  # MQTT inbox listing...
  echo 'MQTT inbox listing...'
  while :
  do
    sleep 2
    if [[ ! -e "$USB_PORT" ]]; then
      break;
    fi
    NEWLINE=$(wc -l < $MQTT_LOG)
    # run below only if new command line is found
    if [[ "$NEWLINE" -gt "$NUMOFLINES" ]]
    then
      NUMOFLINES=$NEWLINE
      # get last line from MQTT log
      LASTCOMMAND=$(tail -n1 $MQTT_LOG)
      echo 'New MQTT command is found'
      echo $LASTCOMMAND
      # Parse line and get last word
      LASTCOMMAND=$(echo $LASTCOMMAND | grep -oE '[^[:space:]]+$')
      # Send last command to Serial
      if [[ $LASTCOMMAND == '1' || $LASTCOMMAND == '0' ]]; then
        sleep 1
        echo $LASTCOMMAND >&99
        echo "The command $LASTCOMMAND has been send"
      fi
    fi

    # Read response from Serial
    #sleep 2 && test -e $USB_PORT && echo "$1" | dd of=$USB_PORT 1>/dev/null 2>/dev/null &
    read -t2 rs_serial <&99

    if [[ $? -le 128 ]]; then
      # Send response to MQTT
      if [[ $rs_serial == '1' || $rs_serial == '0' ]]; then
        mosquitto_pub -h $MQTT_SERVER -u $MQTT_USER -P $MQTT_PASS -p $MQTT_PORT -I $MQTT_RMT_CLIENT_ID -r -d -t $MQTT_RMT_TOPIC -m $rs_serial
      fi
    fi
  done
  echo "USB connection lost..."
exec 99>&-
