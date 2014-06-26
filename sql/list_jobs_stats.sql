set pagesize  9999 
set linesize 9999
set colsep '|'
select job_name, LAST_START_DATE, NEXT_RUN_DATE, LAST_RUN_DURATION, next_run_date, MAX_RUN_DURATION, stop_on_window_close from dba_scheduler_jobs
where upper(job_name) like '%GATH%STAT%'
/
