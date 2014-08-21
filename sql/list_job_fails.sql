set pagesize 9999
set linesize 9999
set feedback off
column log_date format A35
column job_name format A30
column run_duration format A15
column status format A15
ALTER SESSION SET NLS_DATE_FORMAT ='MM-DD-YYYY HH24:MI:SS';
select 
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,log_date
,job_name
,instance_id
,run_duration
,status 
from 
dba_scheduler_job_run_details
where log_date > sysdate - 30
and status <> 'SUCCEEDED'
order by log_date desc
;
