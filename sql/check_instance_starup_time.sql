col HOST_NAME format a20
col STARTUP_TIME format a20
col INSTANCE_NAME format a15
set linesize 120

alter session set nls_date_format = 'DD-MON-YY hh24:mi:ss';

SELECT INSTANCE_NAME, INSTANCE_NUMBER, HOST_NAME , STARTUP_TIME, STATUS FROM  GV$INSTANCE;
