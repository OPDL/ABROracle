set pagesize 99
set linesize 132
col client_name format A15
col window_name format A15
SELECT client_name, window_name, jobs_created, jobs_started, jobs_completed FROM dba_autotask_client_history;

