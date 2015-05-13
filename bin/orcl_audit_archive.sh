#!/bin/bash
# Author: Adam Richards
# note: list archive file contents
#       tar -tzvf orcl_aud_archive_grid.xa02db01.20141106.tar.gz | cut -d' ' -f6 -
ARCDIR="/orabacklin/archive/orcl_audit_archive"
SENDMAIL=1
####################################
# initialize argument variables
DAYS=30
CMDLIST=DB,GRID
####################################
# define usage function
usage()
{
cat << EOF
usage: $(basename $0) options
Author: Adam Richards
archive database and grid audit log based on age in days.

OPTIONS:
-h        help
-c value  [db,grid]
-d value  days.  archive older than 
EOF
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
# process command line arguments
# options with : after them expect an argument
while getopts “hc:d:” OPTION
do
     case $OPTION in
	 h)
	     usage
	     exit 1
	     ;;
	 c)
	     CMDLIST=$OPTARG
	     ;;
	 d)
	     DAYS=$OPTARG
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
####################################
# validate CMD LIST
# force uppercase
CMDLIST=$(echo "${CMDLIST}" | tr '[a-z]' '[A-Z]')
CMDLIST=$(echo "${CMDLIST}" | sort | tr ',' ' ')

for CMD in ${CMDLIST}; do
# clean string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
case "${CMD}" in
"DB")
;;
"GRID")
;;
*)
log "error " "Invalid command  - ${CMD} "
usage
exit 1
;;
esac
done
#######################################################
function log
{
	D=$(date +%F|tr -d ' ')
	T=$(date +%H:%M:%S|tr -d ' ')
	H=$(hostname -s)
	printf "%-11s|%-9s|%-15s|%-10s|%s\n" "${D}" "${T}" "${H}" "${1}" "${2}"
}
#######################################################
function run
{
BFILE="$(basename $AFILE)"
OFILE="${ARCDIR}/${BFILE}"
if [[ -f  "${OFILE}" ]]; then
        log "ERROR" "Archive file already exists. ${OFILE} "
# %q should escape any backslashes in the string.
	printf -v EMAIL_TEXT "${EMAIL_TEXT}Archive file already exists:%s\n" "${OFILE}"
        return 1
fi
/usr/bin/find ${FPATH} -maxdepth 1 -name '*.aud' -type f -mtime +"${DAYS}" -print0 2> /dev/null | /bin/tar -czvf "${AFILE}" --index-file "${LSTFILE}" --null -T -  2> /dev/null
OK=$?
if [[ ! $OK = 0 ]]; then
	log "WARN" "Audit Archive Find failed. Path: ${FPATH} Message: $!"
	return $OK
fi
N=$(cat ${LSTFILE} | wc -l)
MSG=$(printf "Oracle Audit Archive: Path: %s, Number of files: %d " "${FPATH}" "${N}")
printf -v EMAIL_TEXT "${EMAIL_TEXT}${MSG}\n"
log "INFO" "${MSG}"
if [[ ! -f  "${OFILE}" ]]; then
	cp "${AFILE}" "${ARCDIR}"
	OK=$?
	if [[ ! $OK = 0 ]]; then
		log "ERROR" "Audit Archive Copy failed. ${AFILE} $!"
		if [[ -f  "${AFILE}" ]]; then
			rm "${AFILE}"
		fi
		return $OK
	fi
fi
# remove files
if [[ ! -z $LSTFILE ]]; then
N=$(cat "${LSTFILE}" | xargs rm -v 2> /dev/null |wc -l)

MSG=$(printf "Files deleted for Path: %s, %d " "${FPATH}" "${N}")
printf -v EMAIL_TEXT "${EMAIL_TEXT}${MSG}\n"
log "INFO" "${MSG}"
fi
# cleanup
if [[ -f  "${AFILE}" ]]; then
	rm "${AFILE}"
fi
if [[ -f  "${LSTFILE}" ]]; then
	rm "${LSTFILE}"
fi
return 0
}
#######################################################
printf -v EMAIL_TEXT "Oracle Audit File Archive Process\nHost:%s\nStarted : %s \n" "$(hostname -s)" "$(date +'%Y-%m-%d %H:%M:%S')"
#######################################################
for CMD in ${CMDLIST}; do
# clean sid string
CMD=$(printf "%s" "${CMD}" | sed -e 's/^ *//' -e 's/ *$//')
#######################################################
if [[ "${CMD}" = "DB" ]]; then
printf "Oracle Audit File Archive Process Started. %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"
# run on first set of files
LSTFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).lst"
AFILE="/tmp/orcl_audit_archive_db.$(hostname -s).$(date +%Y%m%d).tar.gz"
FPATH='/u01/app/oracle/admin/*/adump'
MSG=$(printf "Oracle Audit Archive Run: Older than %s days, Path: %s" "${DAYS}" "${FPATH}" )
printf -v EMAIL_TEXT "${EMAIL_TEXT}${MSG}\n"
log "INFO" "${MSG}"
run
OK=$?
fi
#######################################################
if [[ "${CMD}" = "GRID" ]]; then
#echo ${OK}
# run on second set of files
LSTFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).lst"
AFILE="/tmp/orcl_audit_archive_grid.$(hostname -s).$(date +%Y%m%d).tar.gz"
FPATH="/u01/app/*/grid*/rdbms/audit"
MSG=$(printf "Oracle Audit Archive Run: Older than %s days, Path: %s" "${DAYS}" "${FPATH}" )
printf -v EMAIL_TEXT "${EMAIL_TEXT}${MSG}\n"
log "INFO" "${MSG}"
run
OK=$?
#echo ${OK}
fi
#######################################################
done
printf -v EMAIL_TEXT "${EMAIL_TEXT}Finished: %s \n" "$(date +'%Y-%m-%d %H:%M:%S')"
################## Send mail notification
if [ $SENDMAIL -eq 1 ];then
DIST="oraclenotify@elpasoco.com"
MS="Oracle Audit Archive"
# actual text to send
MP=/usr/sbin/sendmail
D=$(date +%Y%m%d|tr -d ' ')
T=$(date +%H%M%S|tr -d ' ')


read -r -d '' MAIL_TEMPLATE <<'EOT'
<DOCTYPE HTML PUBLIC \\"-//W3C//DTD HTML 4.01 Transitional//EN\\" \\"http://www.w3.org/TR/html4/loose.dtd\\">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>Title</title>
<style type="text/css">
html,body {margin:0;padding:0;height:100%}
body {height:100%}
</style>
</head>
<body>
<div>
<pre>
${__TEXT}
</pre>
</div>
<div style="margin-top:50px;text-align:center;font-style: italic;font-weight:900">
EPC Oracle Services
</div>
<div style="text-align:right;font-style:italic;">
Adam Richards
</div>
</body>
</html>
EOT

# substitue in data for __TEXT placeholder
# \Q and \E for escaping meta data
MAIL_TEMPLATE=$(echo "${MAIL_TEMPLATE}" | perl -pi -e "s|\\$\{__TEXT\}|${EMAIL_TEXT}|g")
read -r -d '' MSG << EOT
From: oracle@elpasoco.com
To:${DIST}
MIME-Version: 1.0
Subject: ${MS} $(hostname -s) ${D} ${T}
Content-Type: multipart/mixed; boundary="FILEBOUNDARY"

--FILEBOUNDARY
Content-Type: multipart/alternative; boundary="MSGBOUNDARY"

--MSGBOUNDARY
Content-Type: text/html; charset=iso-8859-1
Content-Disposition: inline
$MAIL_TEMPLATE

--MSGBOUNDARY--
--FILEBOUNDARY--
EOT
# Mail it
{
echo "${MSG}"       
} | "${MP}" -t
fi
#########################################
exit 0
