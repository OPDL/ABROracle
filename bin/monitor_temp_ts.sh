#!/bin/bash
HOST=$1
SID=$2
SLEEP=$3
while :;  do echo $(date); orcl_sqlcmd -m "${HOST}" -s "${SID}" -f ~/user/sql/temp_tablespace_report.sql >> ~/logs/${HOST}_${SID}_TEMPTS.log ;sleep ${SLEEP} ; done

