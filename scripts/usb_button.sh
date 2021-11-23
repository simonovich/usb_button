#!/bin/bash

# Comminication between USB-buttons
#
# If problem with USB port, run this:
# stty sane <your_serial_port>
#
cd `dirname $0`
curdir=`pwd`
#
# Load MQTT and Device settings
#
source settings.sh
if [[ $? == 1 ]]; then
  echo 'Please, create Settings.sh and write the parameters into it:';
  echo '';
  echo "MQTT_SERVER='your_mqtt_broker' # mqtt.by";
  echo "MQTT_PORT=your_mqtt_port # 1883, 1884, 1885, 1886, 1887, 1888, 1889";
  echo "MQTT_USER='your_mqtt_login' # user login";
  echo "MQTT_PASS='your_mqtt_password' # user password";
  echo "MQTT_LOC_CLIENT_ID='your_local_id' # local client id";
  echo "MQTT_RM_CLIENT_ID='your_remote_id' # remote client id";
  echo "MQTT_LOC_TOPIC='local_topic_name' # topic for your device";
  echo "MQTT_RMT_TOPIC='remote_topic_name' # topic for remote device";
  echo "MQTT_LOG='path_to_log_file' # log for incoming MQTT messages";
  echo '';
  echo "USB_PORT='your_port' # Serial port (by sample /dev/ttyUSB0 or /dev/ttyACM0)";
  echo '';
  exit;
fi

# Subscribe
`mosquitto_sub -h $MQTT_SERVER -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PASS -I $MQTT_LOC_CLIENT_ID -v -d -t $MQTT_LOC_TOPIC >> $MQTT_LOG &`
echo 'MQTT subscription activated'

NUMOFLINES=$(wc -l < $MQTT_LOG)

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
  echo "MQTT inbox listing..."
  while :
  do
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
      echo "New MQTT command is found"
      echo $LASTCOMMAND
      # Parse line and get last word
      LASTCOMMAND=$(echo $LASTCOMMAND | grep -oE '[^[:space:]]+$')
      # Send last command to Serial
      echo $LASTCOMMAND >&99

      sleep 0.1
    fi

    # Read response from Serial
    #sleep 2 && test -e $USB_PORT && echo "$1" | dd of=$USB_PORT 1>/dev/null 2>/dev/null &
    read -t2 rs_serial <&99

    if [[ $? -le 128 ]]; then
      # Send response to MQTT
      mosquitto_pub -h $MQTT_SERVER -u $MQTT_USER -P $MQTT_PASS -p $MQTT_PORT -I $MQTT_RMT_CLIENT_ID -r -d -t $MQTT_RMT_TOPIC -m $rs_serial
    fi
  done
  echo "USB connection lost..."
exec 99>&-
