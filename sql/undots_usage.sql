select y.tablespace_name, y.totmb "Total size MB", round(x.usedmb*100/y.totmb,2) "% Used"
from
(
select a.tablespace_name, nvl(sum(bytes),0)/(1024*1024) usedmb
from dba_undo_extents a
where tablespace_name in (select upper(value) from gv$parameter where name='undo_tablespace')
and status in ('ACTIVE','UNEXPIRED')
group by a.tablespace_name
) x,
(
select b.tablespace_name, sum(bytes)/(1024*1024) totmb
from dba_data_files b
where tablespace_name in (select upper(value) from gv$parameter where name='undo_tablespace')
group by b.tablespace_name
) y
where y.tablespace_name=x.tablespace_name
order by y.tablespace_name;
