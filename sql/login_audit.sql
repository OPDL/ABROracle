select os_username,
username,
userhost,
to_char(timestamp,'mm/dd/yyyy hh24:mi:ss') timestamp,
returncode
from dba_audit_session
where action_name = 'LOGON'
and returncode > 0
and timestamp > (sysdate-2)
 order by timestamp
/
