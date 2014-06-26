set linesize 100
set pagesize 9999
select count(owner), OWNER 
from DBA_IND_STATISTICS 
where  STALE_STATS = 'YES' and OWNER <> 'SYS'
group by owner
order by 1 desc
/

