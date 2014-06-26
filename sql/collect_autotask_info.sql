ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT ='DD/MM/YYYY HH24:MI:SS TZR TZD';
ALTER SESSION SET NLS_DATE_FORMAT ='DD-MM-YYYY HH24:MI:SS';
set pagesize 9999
spool /tmp/dba_autotask_client.html
set markup html on
select * from DBA_AUTOTASK_CLIENT;
select * from DBA_AUTOTASK_CLIENT_HISTORY;
select * from DBA_AUTOTASK_CLIENT_JOB;
select * from DBA_AUTOTASK_JOB_HISTORY order by JOB_START_TIME;
select * from DBA_AUTOTASK_OPERATION;
select * from DBA_AUTOTASK_SCHEDULE order by START_TIME;
select * from DBA_AUTOTASK_TASK;
select * from DBA_AUTOTASK_WINDOW_CLIENTS;
select * from DBA_AUTOTASK_WINDOW_HISTORY order by WINDOW_START_TIME;
select * from dba_scheduler_windows;
select * from dba_scheduler_window_groups;
select * from dba_scheduler_job_run_details order by ACTUAL_START_DATE;
select * from DBA_SCHEDULER_JOB_LOG;
SELECT program_name, program_action, enabled FROM dba_scheduler_programs;
spool off
set markup html off

