#!/bin/bash
# wrapper fro
# /home/oracle/bin/DB_backup.sh oemdb
# set -x
####################################
# get script directory
SWD=$(dirname ${0})
###################################
# define usage function
usage()
{
cat << EOF
usage: $(basename $0) options
Author: Adam Richards
wrapper for running oracle rman scripts

OPTIONS:
-h        help
-s value  sid 
-e 	  use /etc/oratab for sids
-v        verbose
EOF
}
####################################
# initialize argument variables
SID=0
V=
E=
####################################
# process command line arguments
# options with : after them expect an argument
while getopts “hs:ve” OPTION
do
     case $OPTION in
	 h)
	     usage
	     exit 1
	     ;;
	 s)
	     SID=$OPTARG
	     ;;
	 e)
	     E=1
	     ;;
	 v)
	     V=1
	     ;;
	 ?)
	     usage
	     exit
	     ;;
     esac
done
####################################
if [[ ! -z $E ]]; then
SIDS=$(cat /etc/oratab | egrep -iv '^#|agent|#\s*ignore' | cut -s -d: -f1 )
SIDS=$(echo "${SIDS}" | sort | tr '\r\n' ' ')
echo "${SIDS}"
fi

export NLS_DATE_FORMAT='yyyymmdd hh24:mi:ss'
echo "SID = ${SID}"
. /usr/local/bin/oraenv 2> /dev/null 2&>1 <<EOF
${SID}
EOF
echo $ORACLE_HOME

rman target=/ nocatalog @${HOME}/user/rman/list_backup.rman

