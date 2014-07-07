#!/bin/bash
#set -x
# get SID for current host machine
SID=$(cat /etc/oratab | grep oemdb | head -1 | cut -d: -f1)
###############################
cd $(dirname ${0})
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
###############################
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
echo "NLS_LANG: $NLS_LANG"
###############################
for FILENAME in $(find data/queue/* -type f 2> /dev/null) 
do
echo "Processing: $FILENAME"
fullfilename=$(basename "$FILENAME")
extension="${fullfilename##*.}"
filename="${fullfilename%.*}"
tmpfile="log/${filename}_input_${TS}.txt"
echo "Pre-processing ${fullfilename} to ${tmpfile}"
perl scripts/formatFixedFileUTF8.pl "data/queue/$fullfilename" "${tmpfile}"
echo "Loading from ${tmpfile}"
lfile="log/${filename}_${TS}.log"
bfile="log/${filename}_${TS}.bad.log"
cfile="control/controlfileutf8.ctl"
cstr="user/pass@//host/service"
sqlldr ${cstr} silent=header,feedback  control=${cfile} data=${tmpfile} log=${lfile} bad=${bfile}
OK=$?
# exit codes
#EX_SUCC 0
#EX_FAIL 1
#EX_WARN 2
#EX_FTL  3

if [[ $OK -ne 0 && $OK -ne 2 ]]; then
	echo "Error running sqlldr on ${fullfilename}. return code: ${OK} "
else
	echo "Moving ${fullfilename} out of the queue" 
	mv "data/queue/${fullfilename}" data/archive
fi
rm "${tmpfile}"
done
###############################
