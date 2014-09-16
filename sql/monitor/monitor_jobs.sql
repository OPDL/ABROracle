-- Adam Richards
-- look at jobs over last 7 days
-- DECODE( expression , search , result [, search , result]... [, default] )
-- INSTR(source, string)
define DAYS=7
set pagesize 9999
set linesize 9999
set feedback off
set verify off
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
where log_date > sysdate - &DAYS
and status <> 'SUCCEEDED'
order by log_date desc;


select * from (
select HOST,DBNAME,JOB_NAME,STATUS,count(*) as "CNT" from
(
select 
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,log_date
,case 
when instr(job_name,'ORA$AT_OS_OPT_SY') > 0 then 'ORA$AT_OS_OPT_SY'
when instr(job_name,'ORA$AT_SA_SPC_SY') > 0 then 'ORA$AT_SA_SPC_SY'
when instr(job_name,'ORA$AT_SQ_SQL_SW') > 0 then 'ORA$AT_SQ_SQL_SW'
else job_name
end as job_name
,instance_id
,run_duration
,status 
from 
dba_scheduler_job_run_details
where log_date > sysdate - &DAYS
--and status <> 'SUCCEEDED'
order by log_date desc
)
GROUP BY rollup(HOST,DBNAME,JOB_NAME,STATUS)
)
where length(trim(status)) > 0
order by job_name asc
;

