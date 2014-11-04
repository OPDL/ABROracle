-- elapsed time is in micro seconds
-- 1 hour = 1000000 (us/s) * 60s/m * 60m/h
set pagesize 9999
set colsep |
set linesize 9999
column sql_id format A15
column sql_text format A50
column schema format A20
column load_time format A20
select  
v.SQL_ID,
to_char(v.SQL_TEXT) as "SQL_TEXT",
           v.PARSING_SCHEMA_NAME as SCHEMA,
           v.FIRST_LOAD_TIME as LOAD_TIME,
           v.DISK_READS,
           v.ROWS_PROCESSED,
           v.ELAPSED_TIME,
           v.service
      from gv$sql v
where 
to_date(v.FIRST_LOAD_TIME,'YYYY-MM-DD hh24:mi:ss') > ADD_MONTHS(trunc(sysdate,'MM'),-2)
--and v.parsing_schema_name != 'SYS'
and v.parsing_schema_name != 'DBSNMP'
-- and v.ELAPSED_TIME > 2000000
and upper(to_char(v.SQL_TEXT)) like '%GMCO%BETWEEN%'
-- order by load_time asc
order by v.FIRST_LOAD_TIME desc
/

