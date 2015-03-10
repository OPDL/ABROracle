set pagesize 9999
set linesize 9999
col comp_name format a45 
col version format a25 
col status format a15 
select 
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,comp_name
,version
,status 
from dba_registry ;

