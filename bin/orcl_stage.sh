#!/bin/bash
# set -x
###############################
# Author: Adam Richards
# Description: 
#  extract and copy dump files from a directory
#  to the appropriate Oracle DIR.
#  This is to support datapump imports and exports
###############################
# required variables 
ODIR=DATA_PUMP_DIR_XA_SHARED
###############################
# process command line arguments
usage()
{
cat << EOF
usage: $0 options

Stage dump files to Oracle directory

OPTIONS:
   -h      Show this message
   -s      Oracle SID [required]
   -d      Source directory [required]
EOF
}

# initialize argument variables
SOURCEDIR=
SID=
# options with : after them expect an argument
while getopts “hs:d:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         d)
             SOURCEDIR=$OPTARG
             ;;
         s)
             SID=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $SID ]] || [[ -z $SOURCEDIR ]] 
then
     usage
     exit 1
fi
if [[ ! -d $SOURCEDIR ]]; then
     echo "Source directory $SOURCEDIR does not exist."
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
# get working directory
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
DIRPATH=$(sqlplus -S "/ as sysdba" << EOF
set heading off
select directory_path from dba_directories where directory_name = '${ODIR}';
exit
EOF)
DIRPATH=$(echo $DIRPATH | tr -d '\r\n')
OK=$(echo $DIRPATH | tr -d ' ')
if [[ -z $OK ]]; then
echo "Invalid Oracle directory  ${ODIR}"
exit 1
fi
if [[ ! -d "$DIRPATH" ]]; then
printf "Error finding directory path\n %s" "${DIRPATH}"
exit 1
fi
########################################################
FILELIST=$(ls -c1 ${SOURCEDIR}/*.DMP.gz |sort)
# list files to be extracted
echo "The following files have been identified for extraction:"
for f in ${FILELIST}; do
echo "${f}"
done
# check if files already exist in target directory
ABORT=0
for f in ${FILELIST}; do
  BNAME=$(basename "${f}" .gz)
  TFILE="${DIRPATH}"/"${BNAME}"
  if [[ -f "${TFILE}" ]]; then
	ABORT=1
	echo "Error! target file already exists: ${TFILE}"
  fi
done
if [[ $ABORT = 1 ]]; then
	echo "No action taken."
	exit 1
fi
########################################################
# begin work
STARTTIME=$(date +%s)

echo "Target Oracle directory: ${ODIR}.  Physical path: ${DIRPATH}"
echo "Decompressing DMP files in parallel ... "

########################################################
########################################################
STARTTIME=$(date +%s)
NCPU=$(cat /proc/cpuinfo  | grep "^processor" |wc -l)
THREADMAX=$(echo $( expr 0.20*${NCPU} |bc ) | perl -nl -MPOSIX -e 'print ceil($_);')
echo "Using ${THREADMAX} threads out of ${NCPU} available"
COUNT=0
# dummy first pid
PLIST=""

# LOOP THROUGH FILES
for F in ${FILELIST}; do
COUNT=$(( $COUNT+1 ))

# submit a job
printf "Decompressing %s \n" "$F"
BNAME=$(basename "${F}" .gz)
gzip -dc <  "${F}" > "${DIRPATH}"/"${BNAME}" &
PID=$!
PLIST="${PLIST} $PID"

# limit running processes to max process count
if [[ $(( $COUNT%$THREADMAX )) -eq 0 ]] ; then
        # loop and wait for thread to finish
        while (true); do
        # LOOP THROUGH PID LIST
        for PID in ${PLIST}; do
        ISR=$(ps -p $PID --no-headers | wc -l)
                if [[ $ISR = 0 ]]; then 
                        PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
                        COUNT=$(( $COUNT-1 ))
                fi
        #printf "%s %s %s\n" "${PID}" "${ISR}" "${COUNT}"
        done
        if [[ $COUNT -lt $THREADMAX ]] ; then
                break
        fi 
        printf "Waiting for current threads to finish... %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"
        sleep 10
        done
fi
done

while (true); do
	for PID in ${PLIST}; do 
	ISR=$(ps -p $PID --no-headers | wc -l)
		if [[ $ISR = 0 ]]; then
			PLIST=$(echo "${PLIST}" | sed "s/ $PID//")
			COUNT=$(( $COUNT-1 ))
		fi
	done 

	if [[ $COUNT -eq 0  ]] ; then
		break
	fi

	printf "Waiting for final threads to finish... %s\n" "$(date +'%Y-%m-%d %H:%M:%S')"
	sleep 10
done

########################################################
echo "done"
ENDTIME=$(date +%s)
ETIMESEC=$[ $ENDTIME - $STARTTIME ]
ETIMESTR=$(convertsecs ${ETIMESEC})
TIMESTR=$(echo "Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}")
echo ""
echo ${TIMESTR} 
########################################################
exit 0
