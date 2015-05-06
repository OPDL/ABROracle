#!/bin/bash
# wrapper for expdp of jdeprod
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
printf "***********************************\n"
printf "FULL EXPORT of JDEPROD ************\n"

../bin/orcl_dpexport.sh -s jdeprod1 -t templates/common/exp_full.par -k JDEPRODFULL 

exit 0

