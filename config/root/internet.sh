#!/bin/sh

if [ "$#" -lt "1" ]; then
  echo "Usage: $0 <gateway_ip>"
  exit 1
fi 

echo "Setting default route for usb0 to $1"
ip addr flush dev usb0
ip addr add 192.168.1.1/24 dev usb0
ip route add default via $1 dev usb0

echo "Setting nameserver to 8.8.8.8"
echo "nameserver 8.8.8.8" > /etc/resolv.conf

