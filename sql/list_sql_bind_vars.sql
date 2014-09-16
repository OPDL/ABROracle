DEFINE SQLID='asu9zx1n9vr24';

select 
to_char(a.LAST_ACTIVE_TIME,'YYYY-MM-DD HH24:MI:SS') "LAST_ACTIVE_TIME"  , a.SQL_PROFILE, a.inst_id, c.sql_id, c.address, c.HASH_VALUE, c.child_address, c.child_number, c.position, c.name, c.value_string
from 
gv$sqlarea a, gv$sql_bind_capture c
where 
a.sql_id = c.sql_id
and a.sql_id='&SQLID'
;
