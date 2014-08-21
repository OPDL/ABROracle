#!/bin/bash
# wrapper fro
# /home/oracle/bin/DB_backup.sh oemdb
# set -x
####################################
RMAN_DIR="${HOME}"/user/rman
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
-c	  command: [backup|validate|list|purge]
-s value  sid1[,sid2,sid3]
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
while getopts “hc:s:ve” OPTION
do
     case $OPTION in
	 h)
	     usage
	     exit 1
	     ;;
	 s)
	     SIDS=$OPTARG
	     ;;
	 c)
	     CMD=$OPTARG
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
# validate Arguments
CMD=$(echo $CMD | tr '[a-z]' '[A-Z]')
case "${CMD}" in
"LIST")
;;
"BACKUP")
;;
"VALIDATE")
;;
"PURGE")
;;
*)
printf "Invalid command %s\n"  "${CMD}"
usage
exit 1
;;
esac

if [[ ! -z $E ]]; then
SIDS=$(cat /etc/oratab | egrep -iv '^#|agent|#\s*ignore' | cut -s -d: -f1 )
SIDS=$(echo "${SIDS}" | sort | tr '\r\n' ' ')
else
# validate single sid
SIDS=$(echo "${SIDS}" | sort | tr ',' ' ')
fi
echo "${SIDS}"
####################################
export NLS_DATE_FORMAT='yyyymmdd hh24:mi:ss'

for SID in ${SIDS}; do
SID=$(printf "%s" "${SID}" | sed -e 's/^ *//' -e 's/ *$//')
echo "SID = ${SID}"

. /usr/local/bin/oraenv 2> /dev/null 2>&1 <<EOF
${SID}
EOF
echo $ORACLE_HOME

case "${CMD}" in
"LIST")
rman target=/ nocatalog @"${RMAN_DIR}"/list_backup.rman
;;
"BACKUP")
rman target=/ nocatalog @"${RMAN_DIR}"/backup_${sid}.rman
;;
*)
printf "Invalid command %s\n"  "${CMD}"
exit 1
;;
esac

done
####################################
exit 0

