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
# run from the DBV dir
# get script directory
SWD=$(dirname ${0})
mkdir -p "${SWD}"/../DBV
cd "${SWD}"/../DBV
###############################
# process command line arguments
usage()
{
cat << EOF
usage: $(basename $0) options

Run oracle dbv on an instance;

OPTIONS:
   -h      Show this message
   -s      Oracle SID [required]
   -v      verbose
EOF
}

# initialize argument variables
SID=
V=
# options with : after them expect an argument
while getopts “hvs:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
             SID=$OPTARG
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

if [[ -z $SID ]] 
then
     usage
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
function validateSID()
{
export ORACLE_SID="${1}";export ORAENV_ASK=NO;. oraenv >/dev/null < /dev/null
which rman 1> /dev/null 2>&1
echo $?
}
###############################
VALID=$(validateSID "${SID}")
if [[ $VALID != 0 ]]; then
echo "Invalid SID ${SID}"
exit 1
fi
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
########################################################
# get list of data files for the SID
FILELIST=$(sqlplus -S system/${PWD} << EOF
set heading off
set feedback off
select file_name from dba_data_files order by file_name asc;
exit
EOF
)
########################################################
# create output dir
OUTDIR="${WD}/${SID}/${SID}_dbv_${TS}"
mkdir -p "${OUTDIR}"
###############################
PARFILE=${OUTDIR}/${SID}_dbv_${TS}.par
########################################################
if [[ $V = 1 ]]; then
	printf "Datafiles to process: \n"
	for F in ${FILELIST}; do
	printf "File: %s\n" "${F}"
	done
fi

STARTTIME=$(date +%s)
CNT=0
for F in ${FILELIST}; do
CNT=$(( $CNT +1 )) 
LOGFILE=${OUTDIR}/${SID}_dbv_${TS}_${CNT}.log
PARFILETEXT=$(cat << EOT
LOGFILE=${LOGFILE}
EOT
)
PARFILETEXT=$(cat << EOT
${PARFILETEXT}
file=${F}
EOT
)
echo "${PARFILETEXT}" > "${PARFILE}"
echo "Starting DBV ${F}"
dbv userid=system/${PWD} parfile="${PARFILE}" 2> /dev/null
OK=$?
if [[ ! $OK = 0 ]] && [[ $IGNORE = 0 ]]; then
	printf "Error: dbv failure! %s \n" "${F}"
fi
done

# roll up all the log files into one
LOGFILE=${OUTDIR}/${SID}_dbv_${TS}.log
while read -r F; do
cat "${F}" >> "${LOGFILE}"
rm "${F}"
done << EOT
$(ls -c1r ${OUTDIR}/${SID}_dbv_${TS}_*.log)
EOT

if [[ $V = 1 ]]; then
cat "${LOGFILE}"
fi
########################################################
ENDTIME=$(date +%s)
ETIMESEC=$[ $ENDTIME - $STARTTIME ]
ETIMESTR=$(convertsecs ${ETIMESEC})
TIMESTR="DBV Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}"
echo ${TIMESTR}
echo ${TIMESTR} > ${OUTDIR}/dbv_info_${TS}.txt
########################################################
echo "Completed DBV."
########################################################
echo "Output directory:  ${OUTDIR}"
echo "Logfile:  ${LOGFILE}"
########################################################
exit 0
