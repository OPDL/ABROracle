set pagesize 9999
set linesize 9999
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
and trunc(sysdate)-trunc(job_start_time) <=7
order by  JOB_START_TIME desc
/
