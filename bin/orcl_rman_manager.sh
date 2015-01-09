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
wrapper for running oracle rman scripts.
commands reference external rman script files.
variable subsitution can be used inside some
scripts.
the variable RMAN_DIR defines script directory.

OPTIONS:
-h        help
-c value  command: backup|validate|list|showall|crosscheck|purge[,cmd2,cmd3...cmdN]
-s value  sid1[,sid2,sid3]
-e 	  use /etc/oratab for sids
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
printf "Info| Starting RMAN RUN| %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"

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
	continue
fi

export ORACLE_SID="${SID}";ORAENV_ASK=NO;. oraenv >/dev/null < /dev/null

for CMD in ${CMDLIST}; do
# clean sid string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
printf "Info| Start| %s| %s| %s \n" "${CMD}" "${SID}" "${ORACLE_HOME}"

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
"VALIDATE")
CMDFILE="${RMAN_DIR}/validate.rman"
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

elapsedTime "start"
printf "Info| File| %s \n" "${CMDFILE}"
if [[ ! -f "${CMDFILE}" ]]; then
	printf "RMAN script file %s not found.\n" "${CMDFILE}"
else
rman target=/ nocatalog @"${CMDFILE}"
fi
ET=$(elapsedTime "stop")
printf "Info| Complete| %s| %s| %s\n" "${CMD}" "${SID}" "${ET}"

# remove temp rman file if exists
if [[ -f "${RMANFILE}" ]]; then
	rm "${RMANFILE}"
fi
done

done
####################################
exit 0

