#!/bin/bash

WAVEFORM_PATH="/opt/waveforms/" # must include trailing slash!

echo "WARNING: This script will restart the X server in 10 seconds!"
echo "         Hit ctrl-c now to abort."
echo ""

sleep 10

# stop X if running
echo "Stopping X"
/etc/init.d/X stop 2> /dev/null

echo "Unloading electronic paper display controller kernel module"
modprobe -r mxc_epdc_fb
modprobe eink_fb_waveform
mkdir -p $WAVEFORM_PATH

echo "Extracting waveform"
echo "$WAVEFORM_PATH" > /proc/wf/panel/extract_path
echo "Extracted waveform to $WAVEFORM_PATH"

echo "Re-loading kernel module"
modprobe mxc_epdc_fb

# start X
echo "Re-starting X"
/etc/init.d/X start 2> /dev/null

