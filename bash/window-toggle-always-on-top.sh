#!/bin/bash

# From: https://superuser.com/questions/622937/always-on-top-shortcut-key-in-linux-mint
#
# Script to toggle the always on top setting of the active window. It is 
# designed to work by being assigned to a system hot key.
# REQUIRES wmctrl TO BE INSTALLED

wmctrl -r :ACTIVE: -b toggle,above
exit 0
