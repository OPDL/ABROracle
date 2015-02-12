set pagesize 999
set linesize 999
select inst_id,username, tablespace, contents, segtype,blocks,extents from gv$sort_usage;

