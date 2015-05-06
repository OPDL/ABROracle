set pagesize  9999 
set linesize 9999
set colsep '|'
select JOB_NAME,LOG_DATE,STATUS,trunc(sysdate)-trunc(log_date) as d from dba_scheduler_job_log
where (trunc(sysdate) - trunc(log_date) ) < 14
order by log_date desc
/
