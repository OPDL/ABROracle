#! /bin/ksh
#set -x

#################################################################################################
#                                                                                               #
# Script:     /home/oracle/scripts/purge_em12c_logs.sh                                          #
#                                                                                               # 
# Purpose:    Purge OMS logs files older than x number of days on an EM12c installation.        #
#             Log file locations based on MOS notes 1445743.1 and 1448308.1                     #
#                                                                                               #
#             This can be used on additional OMS installations, but the Admin Server only runs  #
#             from the primary OMS machine, so no EMGC_ADMINSERVER logs will be found.          #
#                                                                                               #
# Typical cron entry (midnight, every Sunday):                                                  #
# 0 0 * * 0 <dir>/purge_em12c_logs.sh > <dir>/purge_em12c_logs.out                              #
#                                                                                               #
# Change Log: 10/07/2013 GH Initial Release                                                     #
#                                                                                               #
#################################################################################################

#############################
# Set environment variables #
#############################

export PURGE_AGE=15
export MW_HOME=/u01/app/oracle/middleware
export EM_INST_HOME=$MW_HOME/oms12c/gc_inst
export AGENT_HOME=$MW_HOME/agent12c

##################
# Start clean up #
##################

echo "FS space check before purge..."
#df -g $EM_INST_HOME
df -h $EM_INST_HOME

#######################################
# Purge Oracle HTTP Server (OHS) logs #
#######################################

echo
echo "Purge Oracle HTTP Server (OHS) logs..."

#cd ${EM_INST_HOME}/WebTierIH1/diagnostics/logs/OHS/ohs1
cd ${EM_INST_HOME}/WebTierIH*/diagnostics/logs/OHS/ohs*
find . \( ! -name . -prune \) -name "access_log.*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "em_upload_https_access_log.*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "em_upload_http_access_log.*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "ohs1-*.log" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "mod_wl_ohs*.log" -mtime +${PURGE_AGE}  -exec rm {} \;

################################################################
# Purge WLS Admin Server logs (only applicable to primary OMS) #
################################################################

echo "Purge WLS Admin Server logs..."

cd ${EM_INST_HOME}/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs
find . \( ! -name . -prune \) -name "EMGC_ADMINSERVER.out0*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "GCDomain.log0*" -mtime +${PURGE_AGE}  -exec rm {} \;

#############################
# Purge WLS OMS Server logs #
#############################

echo "Purge WLS OMS Server logs..."

cd ${EM_INST_HOME}/user_projects/domains/GCDomain/servers/EMGC_OMS*/logs
find . \( ! -name . -prune \) -name "access.log0*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "EMGC_OMS*.out0*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "EMGC_OMS*.log0*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "EMGC_OMS*-diagnostic-*.log" -mtime +${PURGE_AGE}  -exec rm {} \;

#########################
# Purge OMS SYSMAN logs #
#########################

echo "Purge OMS SYSMAN logs..."

cd ${EM_INST_HOME}/em/EMGC_OMS*/sysman/log
find . \( ! -name . -prune \) -name "emoms.trc.*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "emctl.log.*" -mtime +${PURGE_AGE}  -exec rm {} \;

###########################
# Purge Agent SYSMAN logs #
###########################

echo "Purge Agent SYSMAN logs..."

cd ${AGENT_HOME}/agent_inst/sysman/log
find . \( ! -name . -prune \) -name "gcagent.log.*" -mtime +${PURGE_AGE}  -exec rm {} \;
find . \( ! -name . -prune \) -name "gcagent_sdk.trc.*" -mtime +${PURGE_AGE}  -exec rm {} \;

########################################
# Other directories to look out for... #
########################################

#/home/oracle/oradiag_oracle/diag/clients/user_oracle/host_*/alert
#/home/oracle/oradiag_oracle/diag/clients/user_oracle/host_*/trace
#$EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS*/adr/diag/ofm/EMGC_DOMAIN/EMOMS/incident
#$EM_INST_HOME/user_projects/domains/GCDomain/servers/EMGC_OMS*/adr/diag/ofm/GCDomain/EMGC_OMS*/incident

echo
echo "FS space check after purge..."

#df -g $EM_INST_HOME
df -h $EM_INST_HOME

#################
# End of Script #
#################