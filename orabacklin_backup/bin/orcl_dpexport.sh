#!/bin/bash
# set -x
###############################
# Author: Adam Richards
# Description: wrapper for expdp 
# export files are placed in a directory named exports
# in the current working directory.
# update: 07/15/2014
###############################
# required variables 
PWFILE=/orabacklin/work/DBA/SAFE/pwfile
ODIR=DATA_PUMP_DIR_XA_SHARED
SLEEP=10
###############################
# run from the DATAPUMP dir
# get script directory
SWD=$(dirname ${0})
DPDIR="${SWD}"/../DATAPUMP
###############################
# process command line arguments
usage()
{
cat << EOF
usage: $(basename $0) options

Run oracle expdp based on template par file
dump files are gzipped and stored.

OPTIONS:
   -h      Show this message
   -s      Oracle SID [required]
   -t      Parameter template file [required]
   -i      ignore errors 
   -g      stage.  leave DMP files in stage area
   -k      key string.  add a key string to the output directory
EOF
}

# initialize argument variables
TEMPLATEFILE=
SID=
STAGE=0
IGNORE=0
KEYSTRING=
# options with : after them expect an argument
while getopts “hs:t:k:ig” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         t)
             TEMPLATEFILE=$OPTARG
             ;;
         s)
             SID=$OPTARG
             ;;
         k)
             KEYSTRING=$OPTARG
             ;;
         g)
             STAGE=1
             ;;
         i)
             IGNORE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $SID ]] || [[ -z $TEMPLATEFILE ]] 
then
     usage
     exit 1
fi
if [[ ! -f $TEMPLATEFILE ]]; then
     echo "Parameter file $TEMPLATEFILE does not exist."
     exit 1
fi
###############################
function convertsecs {
    h=$(($1/3600))
    m=$((($1/60)%60))
    s=$(($1%60))
    printf "%06d:%02d:%02d" $h $m $s
}
###############################
# get password for password file
PWD=
PWLIST=$(cat ${PWFILE} | tr '\r\n' ' ')
for PWREC in ${PWLIST}; do
PSID=$(echo ${PWREC} | cut -d'|' -f2 )
RE="${SID}?"
if [[ $PSID =~ $RE  ]]; then
PWD=$(echo ${PWREC} | cut -d'|' -f4 )
fi
done
if [[ -z $PWD ]]; then
echo "Unable to lookup password."
exit 1
fi
###############################
# set oracle directory name
WD=$(pwd)
# get time stamp
TS=$(date +%F-%H-%M-%S|tr -d ' ')
###############################
# setup oracle envrionment using oraenv
export ORACLE_SID=$SID;export ORAENV_ASK=NO;source oraenv 1> /dev/null < /dev/null
OK=$(echo $ORACLE_BASE | tr -d ' ')
if [[ -z $OK ]]; then
echo "Invalid SID ${SID}"
exit 1
fi
########################################################
# capture real path for oracle directory 
DIRPATH=$(sqlplus -S system/${PWD} << EOF
set heading off
select directory_path from dba_directories where directory_name = '${ODIR}';
exit
EOF)
DIRPATH=$(echo $DIRPATH | tr -d '\r\n')
OK=$(echo $DIRPATH | tr -d ' ')
if [[ -z $OK ]]; then
echo "Invalid oracle directory  ${ODIR}"
exit 1
fi
printf "Oracle Directory path: %s\n" "$DIRPATH"
########################################################
# create output dir
if [[ -z $KEYSTRING ]]; then
OUTDIR="${DPDIR}/exports/${SID}/${SID}_export_${TS}"
else
KEYSTRING=$(echo "$KEYSTRING" | tr ' ' '-' )
OUTDIR="${DPDIR}/exports/${SID}/${SID}_export_${KEYSTRING}_${TS}"
fi
mkdir -p "${OUTDIR}"
###############################
BNAME=$(basename "${TEMPLATEFILE}" | tr ' ' '_' |tr '.' '_')
PARFILE=${OUTDIR}/${BNAME}_${TS}.par
########################################################
PARFILETEXT=$(cat ${TEMPLATEFILE})
# process substitutions
PARFILETEXT=$(echo "${PARFILETEXT}" | perl -pi -e "s/\\$\{TS\}/${TS}/g")
PARFILETEXT=$(echo "${PARFILETEXT}" | perl -pi -e "s/\\$\{ODIR\}/${ODIR}/g")
PARFILETEXT=$(echo "${PARFILETEXT}" | perl -pi -e "s/\\$\{SID\}/${SID}/g")
echo "${PARFILETEXT}" > ${PARFILE}
########################################################
printf "Parfile to be used: \n"
cat ${PARFILE}
printf "\n"

echo "Starting export datapump"
STARTTIME=$(date +%s)
expdp system/${PWD} parfile=${PARFILE} 
OK=$?
if [[ ! $OK = 0 ]] && [[ $IGNORE = 0 ]]; then
	echo "Error: expdp failed!"
	rm -rfv ${OUTDIR}
	exit $OK
fi
ENDTIME=$(date +%s)
ETIMESEC=$[ $ENDTIME - $STARTTIME ]
ETIMESTR=$(convertsecs ${ETIMESEC})
TIMESTR="Export Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}"
echo ${TIMESTR}
echo ${TIMESTR} > ${OUTDIR}/export_info_${TS}.txt
mv ${DIRPATH}/*${TS}*.log ${OUTDIR}
########################################################
echo "Completed export data pump."
########################################################
STARTTIME=$(date +%s)
NCPU=$(cat /proc/cpuinfo  | grep "^processor" |wc -l)
THREADMAX=$(echo $( expr 0.20*${NCPU} |bc ) | perl -nl -MPOSIX -e 'print ceil($_);')
echo "Using ${THREADMAX} threads out of ${NCPU} available"
echo "Compressing DMP files in parallel ... "
COUNT=0
# dummy first pid
PLIST=""

# LOOP THROUGH FILES
while read -r F; do
COUNT=$(( $COUNT+1 ))

# submit a job
printf "Compressing %s \n" "$F" 
BN=$(basename "${F}")
gzip -c < "${F}" > "${OUTDIR}/${BN}.gz" &
PID=$!
PLIST="${PLIST} $PID"

# limit running processes to max process count
if [[ $(( $COUNT%$THREADMAX )) -eq 0 ]] ; then
	# loop and wait for thread to finish
        printf "Waiting for current threads to finish... %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"
	while (true); do
	printf "Current file count: %s Current process list: [%s]\n" "${COUNT}" "${PLIST}"
        # LOOP THROUGH PID LIST
	for PID in ${PLIST}; do
        ISR=$(ps -p $PID --no-headers | wc -l)
		if [[ $ISR = 0 ]]; then
			printf "... Processes %s finished\n" "${PID}"
			PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
			COUNT=$(( $COUNT-1 ))
		fi
	done
	if [[ $COUNT -lt $THREADMAX ]] ; then
		break
	fi
        sleep ${SLEEP} 
	done
fi
done << EOT
$(find "${DIRPATH}" -type f -name "*${TS}*.DMP" |sort )
EOT

# wait for remaining processes
printf "Waiting for FINAL threads to finish... %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"
while (true); do
	printf "Current file count: %s Current process list: [%s]\n" "${COUNT}" "${PLIST}"
	for PID in ${PLIST}; do
	ISR=$(ps -p $PID --no-headers | wc -l)
		if [[ $ISR = 0 ]]; then
			printf "... Processes %s finished\n" "${PID}"
			PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
			COUNT=$(( $COUNT-1 ))
		fi
	done
	if [[ $COUNT -eq 0  ]] ; then
		break
	fi
	sleep ${SLEEP}
done
printf "Final file count: %s Current process list: [%s]\n" "${COUNT}" "${PLIST}"

ENDTIME=$(date +%s)
ETIMESEC=$[ $ENDTIME - $STARTTIME ]
ETIMESTR=$(convertsecs ${ETIMESEC})
TIMESTR="File Compression Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}"
echo ${TIMESTR}
echo ${TIMESTR} >> ${OUTDIR}/export_info_${TS}.txt
########################################################
if [[ $STAGE = 0 ]]; then
	STARTTIME=$(date +%s)
	echo "Removing dump files from ${DIRPATH} ... "
	rm  ${DIRPATH}/*${TS}* 
	ENDTIME=$(date +%s)
	ETIMESEC=$[ $ENDTIME - $STARTTIME ]
	ETIMESTR=$(convertsecs ${ETIMESEC})
	TIMESTR="Remove dump files. Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}"
	echo ${TIMESTR}
	echo ${TIMESTR} >> ${OUTDIR}/export_info_${TS}.txt
fi
########################################################
IFILE=${OUTDIR}/export_info_${TS}.txt
FP=$(readlink -f "${IFILE}")
FD=$(dirname "${FP}")
echo "Output directory:  ${FD}"
########################################################
exit 0
