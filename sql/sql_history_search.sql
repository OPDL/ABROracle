set pagesize 9999
set colsep |
set linesize 9999
column sql_id format A15
column sql_text format A50
column schema format A20
column load_time format A20
define SKEY="F0902"
select  
v.SQL_ID,
v.SQL_TEXT,
           v.PARSING_SCHEMA_NAME as SCHEMA,
           v.FIRST_LOAD_TIME as LOAD_TIME,
           v.DISK_READS,
           v.ROWS_PROCESSED,
           v.ELAPSED_TIME,
           v.service
      from gv$sql v
where 
to_date(v.FIRST_LOAD_TIME,'YYYY-MM-DD hh24:mi:ss') > ADD_MONTHS(trunc(sysdate,'MM'),-2)
and v.parsing_schema_name != 'SYS'
and v.parsing_schema_name != 'DBSNMP'
--and upper(v.SQL_TEXT) like '%DELETE%'
and upper(v.SQL_TEXT) like '%&SKEY%'
order by load_time asc
/

