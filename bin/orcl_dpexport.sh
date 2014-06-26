#!/bin/bash
# set -x
###############################
# Author: Adam Richards
# Description: wrapper for expdp 
###############################
# required variables 
PWFILE=/orabacklin/work/DATAPUMP/bin/pwfile
ODIR=DATA_PUMP_DIR_XA_SHARED
###############################
# process command line arguments
usage()
{
cat << EOF
usage: $0 options

Run oracle expdp based on template par file

OPTIONS:
   -h      Show this message
   -s      Oracle SID [required]
   -t      Parameter template file [required]
EOF
}

# initialize argument variables
TEMPLATEFILE=
SID=
# options with : after them expect an argument
while getopts “hs:t:” OPTION
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
# get password for password file
PWD=
PWLIST=$(cat ${PWFILE} | tr '\r\n' ' ')
for PWREC in ${PWLIST}; do
PSID=$(echo ${PWREC} | cut -d: -f1 )
RE="${SID}?"
if [[ $PSID =~ $RE  ]]; then
PWD=$(echo ${PWREC} | cut -d: -f2 )
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
OUTDIR=${WD}/exports/${SID}/${SID}_export_${TS} 
mkdir -p ${OUTDIR}
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
if [[ ! $OK = 0 ]]; then
	echo "Error: expdp failed!"
	rm -rfv ${OUTDIR}
	exit $OK
fi
ENDTIME=$(date +%s)
ETIMESEC=$[ $ENDTIME - $STARTTIME ]
function convertsecs {
    h=$(($1/3600))
    m=$((($1/60)%60))
    s=$(($1%60))
    printf "%06d:%02d:%02d" $h $m $s
}
ETIMESTR=$(convertsecs ${ETIMESEC})
TIMESTR=$(echo "Elapsed Time HH:MM:SS ${ETIMESTR}  Total Seconds: ${ETIMESEC}")
echo ${TIMESTR} > ${OUTDIR}/export_info_${TS}.txt
########################################################
echo "Completed export data pump"
echo "Moving dump files to ${OUTDIR} ... "
mv  ${DIRPATH}/*${TS}* ${OUTDIR}
########################################################
NCPU=$(cat /proc/cpuinfo  | grep "^processor" |wc -l)
THREADMAX=$(echo $( expr 0.33*${NCPU} |bc ) | perl -nl -MPOSIX -e 'print ceil($_);')
echo "Using ${THREADMAX} processors out of ${NCPU} available"
echo "Compressing DMP files in parallel ... "
COUNT=0

find "${OUTDIR}" -type f -name "*.DMP" -print0 | while IFS= read -r -d '' F; do
COUNT=$(( $COUNT+1 ))

# submit a job
printf "Compressing %s \n" "$F" 
gzip "${F}" > /dev/null 2>&1 &

if [[ $(( $COUNT%$THREADMAX )) -eq 0 ]] ; then
	printf "Waiting for threads to finish...\n"
	wait
fi
done

# wait for rest to finish
printf "Waiting for final threads to finish...\n"
wait
########################################################
printf "\n\nSummary:\n"
echo ${TIMESTR}
echo "Work directory:  ${OUTDIR}"
########################################################
exit 0
