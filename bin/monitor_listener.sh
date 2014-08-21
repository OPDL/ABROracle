#!/bin/bash
SLEEP=$1
W=$2
LOGFILE=/home/oracle/logs/listenercheck.log
# while :;  do echo $(date) >> "${LOGFILE}"; orcl_listenercheck -m ~/safe/LISTENERFILE -w $W >> "${LOGFILE}" ;sleep ${SLEEP} ; done
while :;  do orcl_listenercheck -m ~/safe/LISTENERFILE -w $W >> "${LOGFILE}" ;sleep ${SLEEP} ; done

