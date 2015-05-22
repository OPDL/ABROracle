SELECT s.sid, s.serial#,
   CASE BITAND(t.flag, POWER(2, 28))
      WHEN 0 THEN 'READ COMMITTED'
      ELSE 'SERIALIZABLE'
   END AS isolation_level
FROM v$transaction t 
JOIN v$session s ON t.addr = s.taddr AND s.sid = sys_context('USERENV', 'SID');

select decode (bitand (t.flag, power (2, 28)), power (2, 28), 'SERIALIZABLE', 'READ COMMITTED')
from v$transaction t, v$session s
where s.taddr = t.addr
and s.audsid = userenv ('sessionid');

