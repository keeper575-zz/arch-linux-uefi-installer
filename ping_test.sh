#!/bin/sh
IP=192.168.1.1
ping -c 1 -t 1 $IP;
if [ $? -eq 0 ]; then
	echo "ip is up";
else
	echo "ip is down";
fi
