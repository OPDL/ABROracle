ALTER SESSION SET NLS_DATE_FORMAT ='DD-MM-YYYY HH24:MI:SS';
set pagesize 9999
set linesize 999
SELECT 
sysdate as DT
,CAST(SYS_CONTEXT('USERENV','SERVER_HOST') as VARCHAR2(15)) as "HOST"
,CAST(SYS_CONTEXT('USERENV','DB_NAME') as VARCHAR2(10)) as "DBNAME"
,A.tablespace_name tablespace
, D.mb_total
,SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used
,D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM v$sort_segment A,
(
SELECT B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
FROM v$tablespace B, v$tempfile C
WHERE B.ts#= C.ts#
GROUP BY B.name, C.block_size
) D
WHERE A.tablespace_name = D.name
GROUP by A.tablespace_name, D.mb_total;
