#!/bin/bash

SRV_NAME='rmtbutton'

# Remove service
systemctl --user stop $SRV_NAME
systemctl --user disable $SRV_NAME
#systemctl --user daemon-reload

# Remove environment variables
unset USB_BUTTON_HOME
systemctl --user unset-environment USB_BUTTON_HOME
