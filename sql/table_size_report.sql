-- Adam Richards
set pagesize 999
set linesize 999
col table_size_in_mb format 99999999.99

SELECT 
CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,CAST(SYS_CONTEXT('USERENV','INSTANCE') as VARCHAR2(4)) as "INST" 
,col.owner 
,col.table_name
,col.col_cnt  AS column_count
,rc.row_cnt   AS row_count
,s.size_in_MB AS table_size_in_MB
FROM
  (
  /* number of columns */
  SELECT upper(owner) owner, upper(table_name) table_name, COUNT(*) col_cnt
  FROM dba_tab_columns 
  where upper(owner) not in ('SYS','SYSTEM','DBSNMP','OUTLN','CTXSYS','EXFSYS','XDB','ODMRSYS','WMSYS')
  GROUP BY 
	upper(owner),upper(table_name)
  ) col
JOIN
  (
  /* number of rows */
select owner, table_name,
       to_number(extractvalue(
                   dbms_xmlgen.getXMLtype ('select count(*) cnt from "'||owner||'"."'||table_name||'"'),
                   '/ROWSET/ROW/CNT')) row_cnt
from dba_tables
where -- a real table
      (   tablespace_name is not null
       or partitioned='YES'
       or nvl(iot_type,'NOT_IOT')='IOT' )
      -- not an iot overflow
  and nvl(iot_type,'NOT_IOT') not in ('IOT_OVERFLOW','IOT_MAPPING')
      -- not a mview log
  and (owner, table_name) not in (select log_owner, log_table from user_mview_logs)
  ) rc
ON 
upper(col.table_name) = upper(rc.table_name)
and
upper(col.owner) = upper(rc.owner)
JOIN
  (
  /* table size in MB */
  SELECT
    owner,
    table_name,
    (SUM(bytes)/1024/1024) size_in_MB
  FROM
    (SELECT owner, segment_name table_name,
      bytes
    FROM dba_segments  /* you can change it to dba_segments */
    WHERE segment_type = 'TABLE'
    )
  GROUP BY 
	owner,
    table_name
  ) s
ON 
upper(col.table_name) = upper(s.table_name)
and
upper(col.owner) = upper(s.owner)
order by owner, table_name
;

