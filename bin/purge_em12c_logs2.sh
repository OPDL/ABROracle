

#!/bin/sh

#find and clean Oracle 12c Agent log files older then 14 days
find /u01/oracle/midw/agent/agent_inst/sysman/log/ -name "gcagent.log.*" -mtime +14 -print|xargs rm
#find and clean Oracle 12c OMS log files older then 14 days
find /u01/oracle/midw/gc_inst/em/EMGC_OMS1/sysman/log/ -name "emoms.trc*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/em/EMGC_OMS1/sysman/log/ -name "emctl.log.*" -mtime +14 -print|xargs rm
#find and clean Oracle 12c Oracle HTTP Server (OHS) log files older then 14 days
find /u01/oracle/midw/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/  -name "access_log*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/  -name "em_upload_https_access_log*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/  -name "ohs1-*.log" -mtime +14 -print|xargs rm
#find and clean Oracle 12c Oracle WebLogic log files older then 14 days
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs/ -name "access.log*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs/ -name "EMGC_OMS1.log*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs/ -name "EMGC_OMS1.out*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs/ -name "EMGC_OMS1-diagnostic*.log" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs -name "EMGC_ADMINSERVER.out*" -mtime +14 -print|xargs rm
find /u01/oracle/midw/gc_inst/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs -name "GCDomain.log*" -mtime +14 -print|xargs rm
#find and clean Oracle 12c OPMN log files older then 14 days
/u01/oracle/midw/gc_inst/WebTierIH1/diagnostics/logs/OPMN/opmn
#find and clean Oracle 12c diagnose folder in oracle home log files older then 14 days
find /home/oracle/oradiag_oracle/diag/clients/user_oracle/host_1387324873_11/alert  -name "log_*.xml" -mtime +14 -print|xargs rm
#the next line is commented for know because on 12c I disabled the module according to metalink note:1396472.1
#cat /u01/oracle/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/mod_wl_ohs.log>/u01/oracle/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/mod_wl_ohs_$DATE_VAR.log >/u01/oracle/gc_inst/WebTierIH1/diagnostics/logs/OHS/ohs1/mod_wl_ohs.log


0 0 * * * /home/oracle/scripts/cleanLOGSgrid.sh > /home/oracle/scripts/cleanLOGSgrid.log 2>&1
