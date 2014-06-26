set linesize 999
set pagesize 999
col HOST_NAME format a20
 col ACCOUNT_STATUS format a18
 col USERNAME format a23
 col PROFILE format a20

 select INSTANCE_NAME, HOST_NAME  from V$INSTANCE;

 select USERNAME, ACCOUNT_STATUS, LOCK_DATE, EXPIRY_DATE, PROFILE from DBA_USERS
order by account_status desc, username;


