#!/bin/bash
# Author: Adam Richards
# scipt will look through all sids and loop through commands
# for each sid.
# set -x
####################################
RMAN_DIR=/orabacklin/work/DBA/RMAN
FAIL_DIST="adamrichards@elpasoco.com,shaunoppenheimer@elpasoco.com"
SUCCESS_DIST="adamrichards@elpasoco.com,shaunoppenheimer@elpasoco.com"
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
wrapper for running oracle rman scripts.
commands reference external rman script files.
variable subsitution can be used inside some
scripts.
the variable RMAN_DIR defines script directory.

OPTIONS:
-h        help
-c value  command: backup|validate|list|summary|showall|crosscheck|purge[,cmd2,cmd3...cmdN]
-s value  sid1[,sid2,sid3]
-e 	  use /etc/oratab for sids
-m        enable mail messages
-u        email success emails as one message
-v        verbose
EOF
}

####################################
# operation to time
####################################
_STARTTIME=
_ENDTTIME=
function elapsedTime()
{
if [[ "${1}" = "start" ]]; then
	_STARTTIME=$(date +%s)
fi
if [[ "${1}" = "stop" ]]; then
	_ENDTIME=$(date +%s)
	ETIMESEC=$[ $_ENDTIME - $_STARTTIME ]
	ETIMESTR=$(convertsecs ${ETIMESEC})
	STIMESTR=$(echo "Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}")
	printf "%s" "${STIMESTR}"
fi
}
####################################
function log
{
	D1=$(date +%F|tr -d ' ')
	T1=$(date +%H:%M:%S|tr -d ' ')
H1=$(hostname -s)
printf "%-11s|%-9s|%-15s|%-10s|%s\n" "${D1}" "${T1}" "${H1}" "${1}" "${2}"
}
####################################
# convert seconds to hours, minutes, seconds
function convertsecs {
    h=$(($1/3600))
    m=$((($1/60)%60))
    s=$(($1%60))
    printf "%06d:%02d:%02d" $h $m $s
}
####################################
function validateSID()
{
export ORACLE_SID="${1}";export ORAENV_ASK=NO;. oraenv >/dev/null < /dev/null
which rman 1> /dev/null 2>&1
echo $?
}
####################################
# add items to path if needed
# needed if running under cron
which oraenv 1> /dev/null 2>&1
OK=$?
if [[ $OK != 0 ]]; then
PATH=/usr/local/bin:${PATH}
fi

####################################
# initialize argument variables
SID=
V=
E=
M=
U=
CMDLIST=
####################################
# process command line arguments
# options with : after them expect an argument
while getopts “hc:s:vemu” OPTION
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
	 m)
	     M=1
	     ;;
	 u)
	     U=1
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
if [[ -z $CMDLIST ]]; then
     usage
     exit 1
fi

if [[ -z $SIDS ]] && [[ -z $E ]] ; then
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
"SUMMARY")
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
log "error " "Invalid command  - ${CMD} "
usage
exit 1
;;
esac
done

if [[ ! -z $E ]]; then
SIDS=$(cat /etc/oratab | egrep -iv '^#|agent|#\s*ignore|+ASM' | cut -s -d: -f1 )
SIDS=$(echo "${SIDS}" | sort | tr '\r\n' ' ')
else
# validate single sid
SIDS=$(echo "${SIDS}" | sort | tr ',' ' ')
fi

####################################
export NLS_DATE_FORMAT='yyyymmdd hh24:mi:ss'

UI=$(date +%Y%m%d%H%M%S.%N)
UFILE=/tmp/rman_manager__summary_${UI}.rman
## Loop through all SIDs
for SID in ${SIDS}; do
# clean sid string
SID=$(printf "%s" "${SID}" | sed -e 's/^ *//' -e 's/ *$//')

# save original sid 
OSID="${SID}"
log "info" "Starting RMAN RUN - $(date +'%Y-%m-%d %H:%M:%S')"

VALID=$(validateSID "${SID}")

if [[ $VALID != 0 ]]; then
# attempt using sid as all lowercase
SID=$(echo "${SID}" | tr '[A-Z]' '[a-z]')
VALID=$(validateSID "${SID}")
fi
if [[ $VALID != 0 ]]; then
# attempt using sid as all uppercase
SID=$(echo "${SID}" | tr '[a-z]' '[A-Z]')
VALID=$(validateSID "${SID}")
fi

# if still not working, then sid must be no good, skip this sid
if [[ $VALID != 0 ]]; then
	printf "Unable to configure SID: %s. Skipping\n" "${OSID}"
	log "error" "Unable to configure SID: ${OSID}. Skipping."
	continue
fi

export ORACLE_SID="${SID}";ORAENV_ASK=NO;. oraenv >/dev/null < /dev/null

for CMD in ${CMDLIST}; do
UI=$(date +%Y%m%d%H%M%S.%N)
TS=$(date +%Y%m%d%H%M%S|tr -d ' ')
D=$(date +%Y%m%d|tr -d ' ')
T=$(date +%H%M%S|tr -d ' ')
# clean sid string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
log "info" "Start - ${CMD} - ${SID} - ${ORACLE_HOME}"

CMDFILE=""
case "${CMD}" in
"LIST")
CMDFILE="${RMAN_DIR}/list.rman"
;;
"SUMMARY")
CMDFILE="${RMAN_DIR}/summary.rman"
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
"VALIDATE")
CMDFILE="${RMAN_DIR}/validate.rman"
;;
"BACKUP")
# check if specific backup script exists for this sid
CMDFILE="${RMAN_DIR}/backup_${SID}.rman"
if [[ ! -f "${CMDFILE}" ]]; then
	# use generic script with variable substitutions
	CMDFILE="${RMAN_DIR}/backup.rman"
fi
log "info" "Template file - ${CMDFILE}"
RMANFILE=/tmp/rman_manager_${UI}.rman
########################################################
RMANFILETEXT=$(cat ${CMDFILE})
# process substitutions
RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{SID\}/${SID}/g")
RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{TS\}/${TS}/g")
RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{T\}/${T}/g")
RMANFILETEXT=$(echo "${RMANFILETEXT}" | perl -pi -e "s/\\$\{D\}/${D}/g")
echo "${RMANFILETEXT}" > ${RMANFILE}
CMDFILE="${RMANFILE}"
;;
*)
log "error " "Invalid command  - ${CMD} - ${SID} "
exit 1
;;
esac

elapsedTime "start"
log "info" "Command file - ${CMDFILE}"
if [[ ! -f "${CMDFILE}" ]]; then
	log "error " "script file ${CMDFILE} not found  - ${CMD} - ${SID} "
else
	# Run the rman command
	LFILE="/tmp/rman_log_${UI}.log"
	rman target=/ nocatalog @"${CMDFILE}" | tee "${LFILE}"
	# scan LFILE for errors
	ERR=$(grep -c -i -e "^RMAN-\|^ORA-" "${LFILE}")

	# if errors send email
	if [[ ! $ERR = "0" ]]; then
		if [[ $M = "1" ]]; then
		LL=$(cat ${LFILE})
		/bin/mail -s "RMAN ERROR: $(hostname -s) ${SID} ${CMD} ${D} ${T}" "${FAIL_DIST}" << EOT
${LL}
EOT
		fi
	else
		if [[ $M = "1" ]] && [[ -z $U ]]; then
		LL=$(cat ${LFILE})
		/bin/mail -s "RMAN SUCCESS: $(hostname -s) ${SID} ${CMD} ${D} ${T}" "${SUCCESS_DIST}" << EOT
${LL}
EOT
		else
			printf "\n%s\n" "RMAN SUCCESS: $(hostname -s) ${SID} ${CMD} ${D} ${T}" >> "${UFILE}"
			cat ${LFILE} >> "${UFILE}"
		fi
	fi

fi
ET=$(elapsedTime "stop")
log "info" "SUCCESS - ${CMD} - ${SID} - ${ET}"

# remove temp rman file if exists
if [[ -f "${RMANFILE}" ]]; then
	rm "${RMANFILE}"
fi
if [[ -f "${LFILE}" ]]; then
	rm "${LFILE}"
fi
done

done

# send success summary 
if [[ $M = "1" ]] && [[ $U = "1" ]]; then
  LL=$(cat ${UFILE})
  /bin/mail -s "RMAN SUCCESS SUMMARY: $(hostname -s) ${D} ${T}" "${SUCCESS_DIST}" << EOT
${LL}
EOT
fi

if [[ -f "${UFILE}" ]]; then
	rm "${UFILE}"
fi
####################################
exit 0

