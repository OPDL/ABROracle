-- Adam Richards
set pagesize 999
set linesize 999
col table_size_in_mb format 99999999.99
set colsep '|'
alter session set nls_date_format="mm/dd/yyyy";
with RS as
(
SELECT CAST(SYS_CONTEXT('USERENV', 'SERVER_HOST') AS VARCHAR2(15)) AS HOST,
  CAST(SYS_CONTEXT('USERENV', 'DB_NAME') AS          VARCHAR2(10)) AS DBNAME,
  CAST(SYS_CONTEXT('USERENV', 'INSTANCE') AS         VARCHAR2(4))  AS INST,
  rc.TABLESPACE_NAME                                               AS TABLESPACE,
  col.owner,
  col.table_name,
  col.col_cnt  AS column_count,
  rc.row_cnt   AS row_count,
  s.size_in_MB AS table_size_in_MB
FROM
  (SELECT upper(dba_tab_columns.OWNER) owner,
    upper(dba_tab_columns.TABLE_NAME) table_name,
    COUNT(*) col_cnt
  FROM dba_tab_columns
  WHERE upper(dba_tab_columns.OWNER) NOT IN ('SYS', 'SYSTEM', 'DBSNMP', 'OUTLN', 'CTXSYS', 'EXFSYS', 'XDB', 'ODMRSYS', 'WMSYS')
  GROUP BY upper(dba_tab_columns.OWNER),
    upper(dba_tab_columns.TABLE_NAME)
  ) col
INNER JOIN
  (SELECT dba_tables.OWNER,
    dba_tables.TABLE_NAME,
    dba_tables.TABLESPACE_NAME,
    to_number(extractvalue(dbms_xmlgen.getXMLtype('select count(*) cnt from "'
    || dba_tables.OWNER
    || '"."'
    || dba_tables.TABLE_NAME
    || '"'), '/ROWSET/ROW/CNT')) row_cnt
  FROM dba_tables
  WHERE (dba_tables.TABLESPACE_NAME                 IS NOT NULL
  OR dba_tables.PARTITIONED                          = 'YES'
  OR NVL(dba_tables.IOT_TYPE, 'NOT_IOT')             = 'IOT')
  AND NVL(dba_tables.IOT_TYPE, 'NOT_IOT') NOT       IN ('IOT_OVERFLOW', 'IOT_MAPPING')
  AND (dba_tables.OWNER, dba_tables.TABLE_NAME) NOT IN
    (SELECT user_mview_logs.LOG_OWNER,
      user_mview_logs.LOG_TABLE
    FROM user_mview_logs
    )
  ) rc
ON upper(col.table_name) = upper(rc.TABLE_NAME)
AND upper(col.owner)     = upper(rc.OWNER)
INNER JOIN
  (SELECT OWNER,
    table_name,
    (SUM(BYTES) / 1024 / 1024) size_in_MB
  FROM
    (SELECT dba_segments.OWNER,
      dba_segments.SEGMENT_NAME table_name,
      dba_segments.BYTES
    FROM dba_segments
    WHERE dba_segments.SEGMENT_TYPE = 'TABLE'
    )
  GROUP BY OWNER,
    table_name
  ) s
ON upper(col.table_name) = upper(s.table_name)
AND upper(col.owner)     = upper(s.OWNER)
ORDER BY s.OWNER,
  s.table_name
  )
  SELECT RS.*,O.CREATED
  FROM RS
  LEFT OUTER JOIN DBA_OBJECTS O
  ON RS.OWNER = O.OWNER and RS.TABLE_NAME = O.OBJECT_NAME;


