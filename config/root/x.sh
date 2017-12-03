#!/bin/bash

modprobe eink_fb_waveform
modprobe eink_fb_hal
modprobe mxc_epdc_fb
modprobe eink_fb_hal_fslepdc # optional bootstrap=0
modprobe eink_fb_shim
DISPLAY=:0 Xorg -modulepath /usr/lib/xorg/modules,/usr/lib/arm-linux-gnueabihf,/usr/lib/arm-linux-gnueabihf/xorg/modules/drivers

