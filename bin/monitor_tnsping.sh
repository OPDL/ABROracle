#!/bin/bash
SLEEP=$1
W=$2
LOGFILE=/home/oracle/logs/tnsping_check.log
# while :;  do echo $(date) >> "${LOGFILE}"; orcl_tnsping -m ~/safe/LISTENERFILE -w $W >> "${LOGFILE}" ;sleep ${SLEEP} ; done
while :;  do orcl_tnsping -m ~/safe/LISTENERFILE -w $W >> "${LOGFILE}" ;sleep ${SLEEP} ; done

