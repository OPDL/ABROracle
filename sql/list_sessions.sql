set pagesize 9999
set linesize 1000
select 
cast(b.inst_id as VARCHAR(4)) as INST
,substr(b.machine,1,6) machine
,b.status
,b.server
,b.sid
,b.serial#
,cast(a.spid as varchar(10)) as spid
,cast(b.username as varchar(10)) as  username
,cast(b.osuser as varchar(10)) as  osuser
,cast(b.program as varchar(35)) as program
 ,b.client_info
from
 gv$process a, gv$session b 
where
a.inst_id=b.inst_id and 
 a.addr=b.paddr 
--and client_info like 'rman%'
;

