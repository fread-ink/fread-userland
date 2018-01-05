#!/bin/bash

echo "Creating device nodes"

set -e
mkdir -p dev
cd dev/
mknod console c 5 1
mknod cpu_dma_latency c 10 62
mknod fb0 c 29 0
mknod full c 1 7
mknod fuse c 10 229
mknod initctl p
mknod kmem c 1 2
mknod kmsg c 1 11
mknod mem c 1 1
mknod mmcblk0 b 179 0
mknod mmcblk0p1 b 179 1
mknod mmcblk0p2 b 179 2
mknod mmcblk0p3 b 179 3
mknod mmcblk0p4 b 179 4
mknod network_latency c 10 61
mknod network_throughput c 10 60
mknod null c 1 3
mknod pmic c 253 0
mknod ppp c 108 0
mknod ptmx c 5 2
mknod pxp_device c 10 63
mknod random c 1 8
mknod rtc0 c 254 0
mknod rtc1 c 254 1
mknod tty c 5 0
mknod tty0 c 4 0
mknod tty1 c 4 1
mknod tty2 c 4 2
mknod tty3 c 4 3
mknod tty4 c 4 4
mknod tty5 c 4 5
mknod tty6 c 4 6
mknod tty7 c 4 7
mknod tty8 c 4 8
chmod 660 tty*
mknod ttymxc0 c 207 16
mknod urandom c 1 9
mknod yoshibutton c 10 158
mknod zero c 1 5

mkdir loop
cd loop/
mknod 0 b 7 0
mknod 1 b 7 1
mknod 2 b 7 2
mknod 3 b 7 3
mknod 4 b 7 4
mknod 5 b 7 5
mknod 6 b 7 6
mknod 7 b 7 7
cd ../
mkdir pts

mkdir input
cd input/

cd ../
mknod event0 c 13 64 # tequila keyboard
mknod event1 c 13 65 # fiveway controller
mknod event2 c 13 66
mknod event3 c 13 67
mknod event4 c 13 68
mknod event5 c 13 69
mknod event6 c 13 70
mknod event7 c 13 71
mknod event8 c 13 72
mknod event9 c 13 73
cd ../../
set +e
