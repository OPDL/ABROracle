column tablespace_name format a14 heading 'Tablespace|Name'
column alloc format 999,999.99
column alloc_e format 999,999 heading 'Alloc|Extents'
column used format 999,999.99
column free format 99,999.99
column free_b format 9,999 heading 'Free|Blocks'
column perc format 999.99
set pagesize 60
compute sum label total of alloc used alloc_e free free_b on report
break on report skip 2

select a.tablespace_name, 
   df.alloc alloc,
   nvl(ds.used,0) used,
	nvl(dae.alloc_e,0) alloc_e,
   nvl(dfs.free,0) free,
	nvl(dfree.free_b,0) free_b,
   nvl(ds.used,0) / df.alloc * 100 perc
from dba_tablespaces a,
   ( select tablespace_name, sum(bytes)/1024/1024  alloc
      from dba_data_files
      group by tablespace_name
   ) df,
   ( select tablespace_name, sum(bytes)/1024/1024 used
      from dba_segments
      group by tablespace_name
   ) ds,
	( select tablespace_name, count(extents) alloc_e
		from dba_segments
		group by tablespace_name
	) dae,
   ( select tablespace_name, sum(bytes)/1024/1024 free
      from dba_free_space
      group by tablespace_name
   ) dfs,
	( select tablespace_name, count(block_id) free_b
		from dba_free_space
		group by tablespace_name
	) dfree
where a.tablespace_name = df.tablespace_name 
	and a.tablespace_name = dae.tablespace_name(+)
   and a.tablespace_name = ds.tablespace_name(+)
   and a.tablespace_name = dfs.tablespace_name(+)
	and a.tablespace_name = dfree.tablespace_name(+)
order by a.tablespace_name;

