select S.USERNAME, s.sid, s.osuser, t.sql_id, sql_text
from gv$sqltext_with_newlines t,gV$SESSION s
where t.address =s.sql_address
and t.hash_value = s.sql_hash_value
-- and s.status = 'ACTIVE'
and t.sql_id like '%24%'
and s.username <> 'SYSTEM'
order by s.sid,t.piece
/
