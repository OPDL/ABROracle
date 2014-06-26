set pagesize 9999
set linesize 9999
col client_name format A35
col task_name format A30
col attributes format A10
col task_target_type format A20
col status format A10
col window_group format A15
col service_name format A10
SELECT client_name, task_name, task_target_type , status
--, attributes 
FROM dba_autotask_task
/
select client_name, status, window_group, SERVICE_NAME
--,extract( hour from MEAN_JOB_DURATION) || ':' || extract(minute from MEAN_JOB_DURATION) as ET
,MEAN_JOB_DURATION
from dba_autotask_client
/

select * from DBA_AUTOTASK_SCHEDULE order by start_time desc
/
SELECT client_name, window_name, jobs_created, jobs_started, jobs_completed
FROM dba_autotask_client_history
WHERE client_name like '%stats%'
/


col window_name format A15
col job_name format A25
col client_name format A35
col job_status format A15
col job_duration format A15
col job_start_time format A40
select 
CLIENT_NAME,JOB_NAME,JOB_STATUS,JOB_START_TIME,JOB_DURATION,JOB_ERROR
--, JOB_INFO ,WINDOW_NAME,WINDOW_START_TIME,WINDOW_DURATION 
from DBA_AUTOTASK_JOB_HISTORY
where upper(client_name) like '%STAT%'
order by  JOB_START_TIME desc
/
