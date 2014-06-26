#!/bin/bash
#from Oracle Sun Database Machine Setup/Configuration Best Practices [ID 1274318.1]
#does not work on cygwin

HOST_NAME=`hostname`; 
DNS_SERVER=`nslookup $HOST_NAME | head -1 | cut -d: -f2 | sed -e 's/^[ \t]*//'`
echo -e "Active DNS Server IP:\t\t$DNS_SERVER" 
echo -n -e "Average for 10 pings in ms:\t"
 ping -c10 $DNS_SERVER | grep -E ^64| cut -d"=" -f 4 | cut -d" " -f 1 | awk '{ SUM += $1} END { print SUM/10}'
