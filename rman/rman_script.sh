#!/bin/bash
#20130509 addeed NLS_DATE for better logging  --swo

export NLS_DATE_FORMAT='yyyymmdd hh24:mi:ss'


DBNAME=${1}
echo "DBNAME = ${DBNAME}"

export PATH=/usr/local/bin:/bin:/usr/bin

. /usr/local/bin/oraenv <<EOF
${DBNAME}1
/u01/app/oracle/product/11.2.0.3/dbhome_1
EOF

/u01/app/oracle/product/11.2.0.3/dbhome_1/bin/rman target=/ @/home/oracle/rman/cmds/backup_${DBNAME}.rman



[oracle@xa02db01 cmds]$ cat backup_idmdev.rman
run {
backup AS COMPRESSED BACKUPSET device type disk tag idmdev_daily_backup database;
backup AS COMPRESSED BACKUPSET device type disk tag idmdev_daily_backup archivelog all not backed up delete all input;
}
exit;

