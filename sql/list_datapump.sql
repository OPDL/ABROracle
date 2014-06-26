set linesize 300
set pagesize 500
col inst_id format A15
col program format A15
col sid format A15
col status format A15
col username format A15
col job_name format A15
col spid format A6
col serial# format A15
col pid format A6
select 
to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') "DATE"
, s.inst_id
, s.program
, s.sid
, s.status
, s.username
, d.job_name
, p.spid
, s.serial#
, p.pid
from gv$session s, gv$process p, dba_datapump_sessions d
where p.addr=s.paddr and s.saddr=d.saddr and s.inst_id=d.inst_id
order by job_name, inst_id;

