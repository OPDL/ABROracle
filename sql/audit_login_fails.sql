col USERHOST format a17
col os_username format a20
col USERNAME format a17
set linesize 120
set pagesize 120

select os_username,
username,
userhost,
to_char(timestamp,'mm/dd/yyyy hh24:mi:ss') timestamp,
returncode
from dba_audit_session
where action_name = 'LOGON'
and returncode > 0
and timestamp > (sysdate-20)
 order by timestamp
/

