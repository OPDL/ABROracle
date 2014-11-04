-- unlock schema exec dbms_stats.unlock_schema_stats('<schema_name>');
set pagesize 9999 linesize 9999
select owner, table_name, stattype_locked from dba_tab_statistics where stattype_locked is not null
order by owner, table_name

/
