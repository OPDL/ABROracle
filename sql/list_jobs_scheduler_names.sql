set pagesize  9999 
set linesize 9999
set colsep '|'
select unique(job_name) from dba_scheduler_jobs
/
