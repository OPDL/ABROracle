set pagesize 100
set linesize 300
select window_name ,last_start_date,enabled ,active,duration from dba_scheduler_windows
order by last_start_date desc
/
