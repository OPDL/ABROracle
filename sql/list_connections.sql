set linesize 300
set pagesize 500
set colsep '|'
col inst_id format 9 
col inst_id HEADING 'INST|ID'
col inst_name format A15
col program format A30
col machine format A20
col sid format 999999
col status format A8
col username format A20
col osuser format A20
col fo_type format A10
col fo_method format A10
col fo format A5
col spid format A7
col serial# format 999999
col pid format 99999

select
to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') "CURRENT DATE"
, s.inst_id
, (select instance_name from gv$instance where instance_number = s.inst_id) as inst_name
, s.machine
, s.type	
, s.osuser
, s.username
, s.program
, s.status
, s.failover_type as FO_TYPE
, s.failover_method as FO_METHOD
, s.failed_over as FO
, s.sid
, p.spid
, s.serial#
, p.pid
from gv$session s, gv$process p
where 
p.addr=s.paddr
and s.username not in ('SYS','DBSNMP') 
-- and s.machine like '%APP%'
order by username, inst_id, s.sid;

