#!/bin/bash
# wrapper for expdp of jdeprod
MAIL_DIST="oraclenotify@elpasoco.com"
ORACLE_SID=jdeprod1

# setup environment for expdp from cron
which perl 1> /dev/null 2>&1
OK=$?
if [[ $OK != 0 ]]; then
PATH=/usr/bin:${PATH}
fi

which oraenv 1> /dev/null 2>&1
OK=$?
if [[ $OK != 0 ]]; then
PATH=/usr/local/bin:${PATH}
fi

ORAENV_ASK=NO
. oraenv

cd /orabacklin/work/DBA/DATAPUMP
printf "*****************************************\n"
printf "CRIT TABLE EXPORT of JDEPROD ************\n"

../bin/orcl_dpexport.sh -s jdeprod1 -t templates/jdeprod/exp_crit_objects.par -k JDECRIT 

# moves backups to archive directory
printf "Moving files to /orabacklin/archive/datapump/jdeprod/jdecrit \n"
find /orabacklin/work/DBA/DATAPUMP/exports/jdeprod1 -type d -name "*JDECRIT*" | xargs -I{} mv -v {} /orabacklin/archive/datapump/jdeprod/jdecrit

# remove archives older than 13 months
printf "Removing old archvies from /orabacklin/archive/datapump/jdeprod/jdecrit \n"
find /orabacklin/archive/datapump/jdeprod/jdecrit/* -maxdepth 1 -type d  -mtime +390 |xargs rm -rfv

D=$(date +%Y%m%d|tr -d ' ')
T=$(date +%H%M%S|tr -d ' ')
/bin/mail -s "JDEPROD Crucial Export Complete: ${D} ${T}" "${MAIL_DIST}" << EOT
Datapump export of JDEPROD Crucial Tables Complete.
Please review logs on xa01db01 /home/oracle/logs
EOT

printf "Finished %s \n" "$(date +%Y%m%d)"
exit 0

