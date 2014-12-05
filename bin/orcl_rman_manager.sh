#!/bin/bash
# Author: Adam Richards
# set -x
####################################
RMAN_DIR="${HOME}"/local/rman
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
-c	  command: backup|validate|list|showall|crosscheck|purge[,cmd2,cmd3...cmdN]
-s value  sid1[,sid2,sid3]
-e 	  use /etc/oratab for sids
-v        verbose
EOF
}

####################################
# initialize argument variables
SID=
V=
E=
CMDLIST=
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
	     CMDLIST=$OPTARG
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
# validate arguments
if [[ -z $CMDLIST ]]
then
     usage
     exit 1
fi

if [[ -z $SIDS ]]
then
     usage
     exit 1
fi
####################################
# validate CMD LIST
# force uppercase
CMDLIST=$(echo "${CMDLIST}" | tr '[a-z]' '[A-Z]')
CMDLIST=$(echo "${CMDLIST}" | sort | tr ',' ' ')

for CMD in ${CMDLIST}; do
# clean sid string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
case "${CMD}" in
"LIST")
;;
"BACKUP")
;;
"VALIDATE")
;;
"PURGE")
;;
"CROSSCHECK")
;;
"SHOWALL")
;;
*)
printf "ERROR! Invalid command \"%s\". exiting.\n\n"  "${CMD}"
usage
exit 1
;;
esac
done

if [[ ! -z $E ]]; then
SIDS=$(cat /etc/oratab | egrep -iv '^#|agent|#\s*ignore' | cut -s -d: -f1 )
SIDS=$(echo "${SIDS}" | sort | tr '\r\n' ' ')
else
# validate single sid
SIDS=$(echo "${SIDS}" | sort | tr ',' ' ')
fi
####################################
export NLS_DATE_FORMAT='yyyymmdd hh24:mi:ss'

## Loop through all SIDs
for SID in ${SIDS}; do
# clean sid string
SID=$(printf "%s" "${SID}" | sed -e 's/^ *//' -e 's/ *$//')

# save original sid 
OSID="${SID}"
printf "***** STARTING RMAN RUN: %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"

unset ORACLE_HOME; unset ORACLE_SID
. /usr/local/bin/oraenv 1> /dev/null 2>&1 <<EOF
${SID}
EOF
which rman 1>/dev/null 2>&1
VALID=$?

if [[ $VALID != 0 ]]; then
# attempt using sid as all lowercase
LSID=$(echo "${SID}" | tr '[A-Z]' '[a-z]')
unset ORACLE_HOME; unset ORACLE_SID
. /usr/local/bin/oraenv 1> /dev/null 2>&1 <<EOF
${LSID}
EOF
which rman 1>/dev/null 2>&1
VALID=$?
fi
if [[ $VALID != 0 ]]; then
# attempt using sid as all uppercase
USID=$(echo "${SID}" | tr '[a-z]' '[A-Z]')
unset ORACLE_HOME; unset ORACLE_SID
. /usr/local/bin/oraenv 1> /dev/null 2>&1 <<EOF
${USID}
EOF
which rman 1>/dev/null 2>&1
VALID=$?
fi

# if still not working, then sid must be no good, skip this sid
if [[ $VALID != 0 ]]; then
	printf "Unable to configure SID: %s. Skipping\n" "${OSID}"
	continue
fi

SID="${ORACLE_SID}"
for CMD in ${CMDLIST}; do
# clean sid string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
printf "Current settings. CMD: %s SID: %s  Oracle Home: %s \n" "${CMD}" "${SID}" "${ORACLE_HOME}"

CMDFILE=""
case "${CMD}" in
"LIST")
CMDFILE="${RMAN_DIR}/list.rman"
;;
"CROSSCHECK")
CMDFILE="${RMAN_DIR}/crosscheck.rman"
;;
"SHOWALL")
CMDFILE="${RMAN_DIR}/showall.rman"
;;
"PURGE")
CMDFILE="${RMAN_DIR}/purge.rman"
;;
"BACKUP")
# check if specific backup script exists for this sid
CMDFILE="${RMAN_DIR}/backup_${SID}.rman"
if [[ ! -f "${CMDFILE}" ]]; then
	# use generic script with variable substitutions
	CMDFILE="${RMAN_DIR}/backup.rman"
	TS=$(date +%F-%H-%M-%S|tr -d ' ')
	RMANFILE=/tmp/rman_manager_${TS}.rman
	########################################################
	RMANFILETEXT=$(cat ${CMDFILE})
	# process substitutions
	RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{SID\}/${SID}/g")
	RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{TS\}/${TS}/g")
	echo "${RMANFILETEXT}" > ${RMANFILE}
	CMDFILE="${RMANFILE}"
fi
;;
*)
printf "Invalid command %s\n"  "${CMD}"
exit 1
;;
esac
printf "Running RMAN on SID %s using file %s \n" "${SID}" "${CMDFILE}"
if [[ ! -f "${CMDFILE}" ]]; then
	printf "RMAN script file %s not found.\n" "${CMDFILE}"
else
rman target=/ nocatalog @"${CMDFILE}"
fi
# remove temp rman file if exists
if [[ -f "${RMANFILE}" ]]; then
	rm "${RMANFILE}"
fi
done

done
####################################
exit 0

